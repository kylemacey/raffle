module SilentAuction
  class CloseItemService
    Result = Struct.new(:success, :message, :invoice_record, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(item)
      @item = item
    end

    def call
      result = nil

      item.with_lock do
        item.reload
        winning_bid = item.winning_bid || item.current_bid

        if winning_bid.blank?
          item.update!(status: "closed", closed_at: item.closed_at || Time.current)
          result = Result.new(success: true, message: "Auction item closed without bids.")
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

    attr_reader :item

    def build_invoice_record(winning_bid)
      invoice_record = item.invoice_record || item.build_invoice_record
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

    def create_stripe_invoice(invoice_record, winning_bid)
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
      invoice_record.update!(sent_at: Time.current) if invoice_record.sent_at.blank?

      Result.new(success: true, message: "Invoice sent to #{winning_bid.bidder_email}.", invoice_record: invoice_record)
    rescue Stripe::StripeError => e
      invoice_record.update!(last_error: e.message)
      Result.new(success: false, message: "Stripe invoice failed: #{e.message}", invoice_record: invoice_record)
    end

    def invoice_params(customer, winning_bid, invoice_setting)
      params = {
        customer: customer.id,
        collection_method: "send_invoice",
        days_until_due: invoice_setting.days_until_due,
        auto_advance: false,
        metadata: invoice_metadata(winning_bid)
      }

      if invoice_setting.stripe_payment_method_configuration_id?
        params[:payment_settings] = {
          payment_method_configuration: invoice_setting.stripe_payment_method_configuration_id
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
