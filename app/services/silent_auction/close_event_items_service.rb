module SilentAuction
  class CloseEventItemsService
    Result = Struct.new(:success, :message, :results, :retryable, keyword_init: true) do
      def success?
        success
      end

      def retryable?
        !!retryable
      end
    end

    def initialize(event)
      @event = event
    end

    def call
      items = items_to_close_or_retry.reject(&:paid_invoice?)
      return Result.new(success: true, message: "No open, paused, or failed invoice silent auction items to close.", results: []) if items.none?

      results = items.map { |item| CloseItemService.new(item).call }
      failures = results.reject(&:success?)

      Result.new(
        success: failures.empty?,
        message: message_for(results, failures),
        results: results,
        retryable: failures.any?(&:retryable?)
      )
    end

    private

    attr_reader :event

    def items_to_close_or_retry
      event.silent_auction_items
           .left_outer_joins(:invoice_record)
           .where(
             <<~SQL.squish,
               silent_auction_items.status IN (:closable_statuses)
               OR (
                 silent_auction_items.status = :closed_status
                 AND invoice_records.id IS NOT NULL
                 AND invoice_records.last_error IS NOT NULL
                 AND invoice_records.last_error != ''
                 AND (invoice_records.stripe_status IS NULL OR invoice_records.stripe_status != :paid_status)
                 AND invoice_records.paid_at IS NULL
                 AND invoice_records.superseded_at IS NULL
               )
             SQL
             closable_statuses: %w[open paused],
             closed_status: "closed",
             paid_status: "paid"
           )
           .includes(:invoice_record)
           .ordered_for_admin
    end

    def message_for(results, failures)
      closed_count = results.count
      invoice_failures = failures.count

      return "Closed #{closed_count} silent auction item#{'s' unless closed_count == 1}." if invoice_failures.zero?

      "Closed #{closed_count} silent auction item#{'s' unless closed_count == 1}; #{invoice_failures} invoice#{'s' unless invoice_failures == 1} need retry."
    end
  end
end
