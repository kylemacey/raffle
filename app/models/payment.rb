class Payment < ApplicationRecord
  belongs_to :entry, optional: true
  belongs_to :order, optional: true

  SUCCESS_STATUSES = [nil, "", "succeeded"].freeze

  def succeeded?
    SUCCESS_STATUSES.include?(status)
  end

  def failed?
    status == "failed"
  end

  def processing?
    status == "processing"
  end

  def stripe_intent_id
    payment_intent_id.presence || stripe_setup_intent_id.presence
  end
end
