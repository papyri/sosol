if defined?(Airbrake) && ENV['AIRBRAKE_HOST'].present? && ENV['AIRBRAKE_PROJECT_KEY'].present?
  Airbrake.configure do |config|
    config.host = ENV.fetch('AIRBRAKE_HOST', nil)
    config.project_id = 1
    config.project_key = ENV.fetch('AIRBRAKE_PROJECT_KEY', nil)
    config.environment = Rails.env
  end
end
