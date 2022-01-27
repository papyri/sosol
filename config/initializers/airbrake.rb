# frozen_string_literal: true

if defined?(Airbrake) && ENV['AIRBRAKE_HOST'].present? && ENV['AIRBRAKE_PROJECT_KEY'].present?
  Airbrake.configure do |config|
    config.host = ENV['AIRBRAKE_HOST']
    config.project_id = 1
    config.project_key = ENV['AIRBRAKE_PROJECT_KEY']
    config.environment = Rails.env
  end
end
