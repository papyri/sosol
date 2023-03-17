Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "jruby" => "JRuby",
    "cts" => "CTS",
    "ddb" => "DDB",
    "hgv" => "HGV",
    "dclp" => "DCLP",
    "apis" => "APIS",
    "ddb_identifier" => "DDBIdentifier",
    "hgv_meta_identifier" => "HGVMetaIdentifier",
    "hgv_meta_identifier_helper" => "HGVMetaIdentifierHelper",
    "dclp_meta_identifier" => "DCLPMetaIdentifier",
    "dclp_meta_identifier_helper" => "DCLPMetaIdentifierHelper",
    "dclp_text_identifier" => "DCLPTextIdentifier",
    "dclp_text_identifier_helper" => "DCLPTextIdentifierHelper"
    "apis_identifier" => "APISIdentifier",
    "jruby_xml" => "JRubyXML"
  )
end
