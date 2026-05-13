module SilentAuction
  class CloseItemJob < ApplicationJob
    class RetryableFailure < StandardError; end

    queue_as :default

    retry_on RetryableFailure,
             ActiveRecord::Deadlocked,
             ActiveRecord::LockWaitTimeout,
             wait: 30.seconds,
             attempts: 5

    discard_on ActiveJob::DeserializationError do |job, error|
      Rails.logger.warn "#{job.class.name}: discarded missing record: #{error.message}"
    end

    def perform(item, winning_bid_id: nil, replace_invoice: false)
      winning_bid = resolve_winning_bid(item, winning_bid_id)
      return if winning_bid_id.present? && winning_bid.blank?

      result = CloseItemService.new(
        item,
        winning_bid: winning_bid,
        replace_invoice: replace_invoice
      ).call

      log_result(item, result)
      raise RetryableFailure, result.message if result.retryable?
    end

    private

    def resolve_winning_bid(item, winning_bid_id)
      return if winning_bid_id.blank?

      item.silent_auction_bids.find_by(id: winning_bid_id).tap do |bid|
        unless bid
          Rails.logger.warn "SilentAuction::CloseItemJob: bid #{winning_bid_id} no longer exists for item ##{item.id}."
        end
      end
    end

    def log_result(item, result)
      if result.success?
        Rails.logger.info "SilentAuction::CloseItemJob: #{result.message} Item ##{item.id}."
      else
        Rails.logger.error "SilentAuction::CloseItemJob: #{result.message} Item ##{item.id}."
      end
    end
  end
end
