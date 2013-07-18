# Load the rails application
require File.expand_path('../application', __FILE__)

# Set default encoding to UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Initialize the rails application
Sosol::Application.initialize!
