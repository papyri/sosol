require 'silencer/logger'

Rails.application.configure do
  config.middleware.swap Rails::Rack::Logger, Silencer::Logger, :silence => ["/editor/user/info", "/editor/user/info.json", "/user/info", "/user/info.json"]
end
