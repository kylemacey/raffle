module SilentAuction
  class CloseItemService
    RETRYABLE_STRIPE_ERRORS = [
      Stripe::APIConnectionError,
      Stripe::APIError,
      Stripe::RateLimitError
    ].freeze

    Result = Struct.new(:success, :message, :invoice_record, :retryable, keyword_init: true) do
      def success?
        success
      end

      def retryable?
        !!retryable
      end
    end

    def initialize(item, winning_bid: nil, replace_invoice: false)
      @item = item
      @requested_winning_bid = winning_bid
      @replace_invoice = replace_invoice
    end

    def call
      result = nil

      item.with_lock do
        item.reload
        winning_bid = requested_winning_bid || item.winning_bid || item.current_bid

        if winning_bid.blank?
          item.update!(status: "closed", closed_at: item.closed_at || Time.current)
          result = Result.new(success: true, message: "Auction item closed without bids.")
        elsif requested_winning_bid.present? && requested_winning_bid.silent_auction_item_id != item.id
          result = Result.new(success: false, message: "Selected bid does not belong to this auction item.")
        elsif replace_invoice && !item.closed?
          result = Result.new(success: false, message: "Only closed auction items can have a new winner selected.")
        elsif replace_invoice && winning_bid == item.winning_bid
          result = Result.new(success: false, message: "Selected bid is already the current winner.")
        elsif replace_invoice
          result = replace_winner_and_invoice(winning_bid)
        else
          item.update!(
            status: "closed",
            closed_at: item.closed_at || Time.current,
            winning_bid: winning_bid
          )

          invoice_record = build_invoice_record(winning_bid)
          result = if invoice_complete?(invoice_record)
                     Result.new(success: true, message: "Invoice already created.", invoice_record: invoice_record)
                   else
                     create_stripe_invoice(invoice_record, winning_bid)
                   end
        end
      end

      result
    end

    private

    attr_reader :item, :requested_winning_bid, :replace_invoice

    def build_invoice_record(winning_bid)
      invoice_record = item.invoice_record || item.invoice_records.build
      invoice_record.assign_attributes(
        amount_cents: winning_bid.amount_cents,
        customer_name: winning_bid.bidder_name,
        customer_email: winning_bid.bidder_email,
        customer_phone: winning_bid.bidder_phone
      )
      invoice_record.save!
      invoice_record
    end

    def build_replacement_invoice_record(winning_bid)
      item.invoice_records.build(
        amount_cents: winning_bid.amount_cents,
        customer_name: winning_bid.bidder_name,
        customer_email: winning_bid.bidder_email,
        customer_phone: winning_bid.bidder_phone
      ).tap(&:save!)
    end

    def replace_winner_and_invoice(winning_bid)
      current_invoice = item.invoice_record
      return Result.new(success: false, message: "The current invoice is already paid. Handle it manually before selecting a new winner.", invoice_record: current_invoice) if current_invoice&.paid?

      if current_invoice&.voidable?
        void_current_invoice(current_invoice)
        return Result.new(success: false, message: "The current invoice is already paid. Handle it manually before selecting a new winner.", invoice_record: current_invoice) if current_invoice.reload.paid?
      end

      current_invoice&.mark_superseded!
      item.association(:invoice_record).reset
      item.update!(
        status: "closed",
        closed_at: item.closed_at || Time.current,
        winning_bid: winning_bid
      )

      create_stripe_invoice(build_replacement_invoice_record(winning_bid), winning_bid, replacement: true)
    rescue Stripe::StripeError => e
      current_invoice&.update!(last_error: "Could not replace winner: #{e.message}")
      Result.new(
        success: false,
        message: "Could not replace winner: #{e.message}",
        invoice_record: current_invoice,
        retryable: retryable_stripe_error?(e)
      )
    end

    def create_stripe_invoice(invoice_record, winning_bid, replacement: false)
      customer = find_or_create_customer(winning_bid)
      invoice_setting = InvoiceSetting.current
      invoice_record.update!(stripe_customer_id: customer.id)

      invoice = stripe_invoice_for_record(invoice_record, customer, winning_bid, invoice_setting)
      ensure_invoice_item(invoice, customer, winning_bid)

      finalized_invoice = finalize_invoice(invoice)
      sent_invoice = send_invoice(invoice_record, finalized_invoice)
      invoice_record.sync_from_stripe_invoice!(sent_invoice)
      invoice_record.update!(
        sent_at: invoice_record.sent_at || Time.current,
        due_at: invoice_record.due_at || invoice_setting.days_until_due.days.from_now,
        last_error: nil
      )

      message = replacement ? "New winner selected and invoice sent to #{winning_bid.bidder_email}." : "Invoice sent to #{winning_bid.bidder_email}."
      Result.new(success: true, message: message, invoice_record: invoice_record)
    rescue Stripe::StripeError => e
      invoice_record.update!(last_error: e.message)
      Result.new(
        success: false,
        message: "Stripe invoice failed: #{e.message}",
        invoice_record: invoice_record,
        retryable: retryable_stripe_error?(e)
      )
    end

    def invoice_complete?(invoice_record)
      invoice_record.stripe_invoice_id.present? &&
        invoice_record.last_error.blank? &&
        invoice_record.finalized_at.present? &&
        invoice_record.sent_at.present?
    end

    def stripe_invoice_for_record(invoice_record, customer, winning_bid, invoice_setting)
      if invoice_record.stripe_invoice_id.present?
        Stripe::Invoice.retrieve(invoice_record.stripe_invoice_id)
      else
        Stripe::Invoice.create(invoice_params(customer, winning_bid, invoice_setting)).tap do |invoice|
          invoice_record.update!(
            stripe_invoice_id: stripe_value(invoice, :id),
            stripe_status: stripe_value(invoice, :status)
          )
        end
      end
    end

    def ensure_invoice_item(invoice, customer, winning_bid)
      return if stripe_value(invoice, :status) != "draft"
      return if invoice_item_present?(invoice, winning_bid)

      Stripe::InvoiceItem.create(
        customer: customer.id,
        invoice: stripe_value(invoice, :id),
        amount: winning_bid.amount_cents,
        currency: "usd",
        description: invoice_description,
        metadata: invoice_metadata(winning_bid)
      )
    end

    def invoice_item_present?(invoice, winning_bid)
      invoice_line_items(invoice).any? do |line_item|
        stripe_value(line_item, :amount).to_i == winning_bid.amount_cents &&
          line_item_for_current_auction?(line_item)
      end
    end

    def invoice_line_items(invoice)
      stripe_collection_data(stripe_value(invoice, :lines))
    end

    def line_item_for_current_auction?(line_item)
      metadata = stripe_value(line_item, :metadata)
      stripe_metadata_value(metadata, :silent_auction_item_id).to_s == item.id.to_s ||
        stripe_value(line_item, :description).to_s == invoice_description
    end

    def finalize_invoice(invoice)
      return invoice unless stripe_value(invoice, :status) == "draft"

      Stripe::Invoice.finalize_invoice(stripe_value(invoice, :id))
    end

    def send_invoice(invoice_record, invoice)
      return invoice if invoice_record.sent_at.present?

      Stripe::Invoice.send_invoice(stripe_value(invoice, :id))
    end

    def void_current_invoice(invoice_record)
      voided_invoice = Stripe::Invoice.void_invoice(invoice_record.stripe_invoice_id)
      invoice_record.sync_from_stripe_invoice!(voided_invoice)
      invoice_record.update!(voided_at: Time.current) if invoice_record.voided_at.blank?
    rescue Stripe::InvalidRequestError => e
      remote_invoice = Stripe::Invoice.retrieve(invoice_record.stripe_invoice_id)
      invoice_record.sync_from_stripe_invoice!(remote_invoice)

      case stripe_value(remote_invoice, :status)
      when "void"
        invoice_record.update!(voided_at: Time.current) if invoice_record.voided_at.blank?
      when "paid"
        nil
      else
        raise e
      end
    end

    def invoice_params(customer, winning_bid, invoice_setting)
      params = {
        customer: customer.id,
        collection_method: "send_invoice",
        days_until_due: invoice_setting.days_until_due,
        auto_advance: false,
        metadata: invoice_metadata(winning_bid)
      }

      if invoice_setting.payment_method_types?
        params[:payment_settings] = {
          payment_method_types: invoice_setting.payment_method_types
        }
      end

      params
    end

    def find_or_create_customer(winning_bid)
      existing_customer = existing_customer_for_email(winning_bid.bidder_email)
      return existing_customer if existing_customer

      Stripe::Customer.create(
        email: winning_bid.bidder_email,
        name: winning_bid.bidder_name,
        phone: winning_bid.bidder_phone
      )
    end

    def existing_customer_for_email(email)
      normalized_email = email.to_s.strip.downcase
      escaped_email = normalized_email.gsub("\\", "\\\\\\").gsub("'", "\\\\'")
      results = Stripe::Customer.search(query: "email:'#{escaped_email}'", limit: 100)
      customers = stripe_collection_data(results)
      matches = customers.select { |customer| stripe_value(customer, :email).to_s.downcase == normalized_email }
      matches.max_by { |customer| stripe_value(customer, :created).to_i }
    end

    def stripe_collection_data(collection)
      if collection.respond_to?(:data)
        collection.data
      else
        Array(collection)
      end
    end

    def invoice_description
      "Silent Auction: #{item.name}"
    end

    def invoice_metadata(winning_bid)
      {
        event_id: item.event_id,
        silent_auction_item_id: item.id,
        silent_auction_bid_id: winning_bid.id,
        invoice_record_source_type: item.class.name,
        invoice_record_source_id: item.id
      }
    end

    def stripe_value(object, key)
      if object.respond_to?(key)
        object.public_send(key)
      elsif object.respond_to?(:[])
        object[key.to_s] || object[key]
      end
    end

    def stripe_metadata_value(metadata, key)
      if metadata.respond_to?(key)
        metadata.public_send(key)
      elsif metadata.respond_to?(:[])
        metadata[key.to_s] || metadata[key]
      end
    end

    def retryable_stripe_error?(error)
      RETRYABLE_STRIPE_ERRORS.any? { |error_class| error.is_a?(error_class) }
    end
  end
end
