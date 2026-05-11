module SilentAuction
  class CloseEventItemsService
    Result = Struct.new(:success, :message, :results, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(event)
      @event = event
    end

    def call
      items = event.silent_auction_items.where(status: %w[open paused]).ordered_for_admin
      return Result.new(success: true, message: "No open or paused silent auction items to close.", results: []) if items.none?

      results = items.map { |item| CloseItemService.new(item).call }
      failures = results.reject(&:success?)

      Result.new(
        success: failures.empty?,
        message: message_for(results, failures),
        results: results
      )
    end

    private

    attr_reader :event

    def message_for(results, failures)
      closed_count = results.count
      invoice_failures = failures.count

      return "Closed #{closed_count} silent auction item#{'s' unless closed_count == 1}." if invoice_failures.zero?

      "Closed #{closed_count} silent auction item#{'s' unless closed_count == 1}; #{invoice_failures} invoice#{'s' unless invoice_failures == 1} need retry."
    end
  end
end
