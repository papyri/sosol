Rails.autoloaders.each do |autoloader|
  autoloader.inflector = Zeitwerk::Inflector.new
  autoloader.inflector.inflect(
    "jruby" => "JRuby",
    "cts" => "CTS",
    "tei" => "TEI",
    "oac" => "OAC",
    "ddb" => "DDB",
    "hgv" => "HGV",
    "dclp" => "DCLP",
    "apis" => "APIS",
    "ddb_identifier" => "DDBIdentifier",
    "hgv_identifier" => "HGVIdentifier",
    "hgv_meta_identifier" => "HGVMetaIdentifier",
    "hgv_trans_identifier" => "HGVTransIdentifier",
    "hgv_meta_identifier_helper" => "HGVMetaIdentifierHelper",
    "dclp_meta_identifier" => "DCLPMetaIdentifier",
    "dclp_meta_identifier_helper" => "DCLPMetaIdentifierHelper",
    "dclp_text_identifier" => "DCLPTextIdentifier",
    "dclp_text_identifier_helper" => "DCLPTextIdentifierHelper",
    "apis_identifier" => "APISIdentifier",
    "apis_identifier_helper" => "APISIdentifierHelper",
    "cts_inventory_identifier" => "CTSInventoryIdentifier",
    "cts_oac_identifier" => "CTSOACIdentifier",
    "tei_cts_identifier" => "TEICTSIdentifier",
    "tei_trans_cts_identifier" => "TEITransCTSIdentifier",
    "numbers_rdf" => "NumbersRDF",
    "jruby_xml" => "JRubyXML",
    "jgit" => "JGit"
  )
end
