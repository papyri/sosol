# Load the rails application
require File.expand_path('../application', __FILE__)

# Set default encoding to UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# See https://groups.google.com/forum/#!topic/rubyonrails-security/61bkgvnSGTQ/discussion
# Disabling because Rails 3 seems to be parsing the xml of posted treebank
# data into JSON which takes a long time for large files
ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete(Mime::XML)

# Initialize the rails application
Sosol::Application.initialize!
