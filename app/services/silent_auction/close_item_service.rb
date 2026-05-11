module SilentAuction
  class CloseItemService
    Result = Struct.new(:success, :message, :invoice_record, keyword_init: true) do
      def success?
        success
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
          result = if invoice_record.stripe_invoice_id.present?
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
        customer_phone: winning_bid.bidder_phone,
        last_error: nil
      )
      invoice_record.save!
      invoice_record
    end

    def build_replacement_invoice_record(winning_bid)
      item.invoice_records.build(
        amount_cents: winning_bid.amount_cents,
        customer_name: winning_bid.bidder_name,
        customer_email: winning_bid.bidder_email,
        customer_phone: winning_bid.bidder_phone,
        last_error: nil
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
      Result.new(success: false, message: "Could not replace winner: #{e.message}", invoice_record: current_invoice)
    end

    def create_stripe_invoice(invoice_record, winning_bid, replacement: false)
      customer = find_or_create_customer(winning_bid)
      invoice_setting = InvoiceSetting.current
      invoice_record.update!(stripe_customer_id: customer.id)

      invoice = Stripe::Invoice.create(invoice_params(customer, winning_bid, invoice_setting))

      invoice_record.update!(
        stripe_invoice_id: invoice.id,
        stripe_status: stripe_value(invoice, :status)
      )

      Stripe::InvoiceItem.create(
        customer: customer.id,
        invoice: invoice.id,
        amount: winning_bid.amount_cents,
        currency: "usd",
        description: invoice_description,
        metadata: invoice_metadata(winning_bid)
      )

      finalized_invoice = Stripe::Invoice.finalize_invoice(invoice.id)
      sent_invoice = Stripe::Invoice.send_invoice(finalized_invoice.id)
      invoice_record.sync_from_stripe_invoice!(sent_invoice)
      invoice_record.update!(
        sent_at: invoice_record.sent_at || Time.current,
        due_at: invoice_record.due_at || InvoiceSetting.current.days_until_due.days.from_now
      )

      message = replacement ? "New winner selected and invoice sent to #{winning_bid.bidder_email}." : "Invoice sent to #{winning_bid.bidder_email}."
      Result.new(success: true, message: message, invoice_record: invoice_record)
    rescue Stripe::StripeError => e
      invoice_record.update!(last_error: e.message)
      Result.new(success: false, message: "Stripe invoice failed: #{e.message}", invoice_record: invoice_record)
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
  end
end
