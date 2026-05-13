module InvoiceRecords
  class CreateOrderFromPaidInvoiceService
    SILENT_AUCTION_PRODUCT_TYPE = "silent_auction".freeze

    def initialize(invoice_record, stripe_invoice: nil)
      @invoice_record = invoice_record
      @stripe_invoice = stripe_invoice
    end

    def call
      return invoice_record.order if invoice_record.order_id.present?
      return unless invoice_record.paid?
      return unless silent_auction_invoice?

      invoice_record.with_lock do
        invoice_record.reload
        return invoice_record.order if invoice_record.order_id.present?
        return unless invoice_record.paid?

        create_order!
      end
    end

    private

    attr_reader :invoice_record, :stripe_invoice

    def create_order!
      item = invoice_record.source
      order = item.event.orders.create!(
        customer_name: invoice_record.customer_name,
        customer_email: invoice_record.customer_email,
        customer_phone: invoice_record.customer_phone,
        total_amount: invoice_record.amount_cents,
        user: system_user,
        payment_method_type: payment_method_type
      )

      order.order_items.create!(
        pos_product: silent_auction_product(item),
        quantity: 1,
        unit_price: invoice_record.amount_cents
      )

      order.create_payment!(
        payment_method_type: payment_method_type,
        amount: invoice_record.amount_cents,
        payment_intent_id: invoice_payment_intent_id,
        stripe_invoice_id: invoice_record.stripe_invoice_id,
        status: "succeeded"
      )

      invoice_record.update!(order: order, last_error: nil)
      order
    end

    def silent_auction_invoice?
      invoice_record.source_type == "SilentAuctionItem" && invoice_record.source.present?
    end

    def silent_auction_product(item)
      product = PosProduct
                .where(product_type: SILENT_AUCTION_PRODUCT_TYPE)
                .where("configuration @> ?", { silent_auction_item_id: item.id }.to_json)
                .first_or_initialize

      product.assign_attributes(
        name: "Silent Auction: #{item.name}",
        price: invoice_record.amount_cents,
        product_type: SILENT_AUCTION_PRODUCT_TYPE,
        active: false,
        description: item.description,
        configuration: product.configuration.to_h.merge("silent_auction_item_id" => item.id)
      )
      product.save! if product.changed?
      product
    end

    def system_user
      User.joins(:roles).where(roles: { key: "platform_admin" }).order(:id).first || User.order(:id).first
    end

    def payment_method_type
      "stripe_invoice"
    end

    def invoice_payment_intent_id
      payment_intent = stripe_value(stripe_invoice, :payment_intent)
      return payment_intent.id if payment_intent.respond_to?(:id)

      payment_intent.presence
    end

    def stripe_value(object, key)
      return if object.blank?

      if object.respond_to?(key)
        object.public_send(key)
      elsif object.respond_to?(:[])
        object[key.to_s] || object[key]
      end
    end
  end
end
