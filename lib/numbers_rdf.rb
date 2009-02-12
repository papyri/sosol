module NumbersRDF
  NUMBERS_SERVER_BASE_URL = 'http://appdev.cul.columbia.edu:8082/numbers/'
  # OAI identifiers should be in the form scheme ":" namespace-identifier ":" local-identifier
  OAI_SCHEME = 'oai'
  OAI_NAMESPACE_IDENTIFIER = 'papyri.info'
  OAI_IDENTIFIER_PREFIX = "#{OAI_SCHEME}:#{OAI_NAMESPACE_IDENTIFIER}:"
  
  def identifier_to_local_identifier(identifier)
    identifier.split(OAI_IDENTIFIER_PREFIX)[1]
  end
  
  def numbers_identifier_to_url(identifier)
    local_identifier = identifier_to_local_identifier(identifier)
    url_paths = local_identifier.split(':')
    return NUMBERS_SERVER_BASE_URL + url_paths.join('/')
  end
  
  class NumbersHelper
    
  end
end