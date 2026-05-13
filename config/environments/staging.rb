require_relative "production"

Rails.application.configure do
  # Staging mirrors production but writes environment-specific queue names.
  config.active_job.queue_adapter = :good_job
  config.active_job.queue_name_prefix = "raffle_staging"
  config.good_job.execution_mode = :external
  config.good_job.queues = ENV.fetch("GOOD_JOB_QUEUES", "*")
  config.good_job.max_threads = ENV.fetch("GOOD_JOB_MAX_THREADS", 5).to_i
  config.good_job.poll_interval = ENV.fetch("GOOD_JOB_POLL_INTERVAL", 10).to_i
  config.good_job.shutdown_timeout = ENV.fetch("GOOD_JOB_SHUTDOWN_TIMEOUT", 30).to_i
end
