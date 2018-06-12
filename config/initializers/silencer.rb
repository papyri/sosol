require 'silencer/logger'

Sosol::Application.config.middleware.swap Rails::Rack::Logger, Silencer::Logger, :silence => ["/editor/user/info", "/editor/user/info.json", "/user/info", "/user/info.json"]
