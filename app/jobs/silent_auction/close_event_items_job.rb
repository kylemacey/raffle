module SilentAuction
  class CloseEventItemsJob < ApplicationJob
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

    def perform(event)
      result = CloseEventItemsService.new(event).call

      if result.success?
        Rails.logger.info "SilentAuction::CloseEventItemsJob: #{result.message} Event ##{event.id}."
      else
        Rails.logger.error "SilentAuction::CloseEventItemsJob: #{result.message} Event ##{event.id}."
      end

      raise RetryableFailure, result.message if result.retryable?
    end
  end
end
