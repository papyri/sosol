# This is where we configure site specific details
Sosol::Application.configure do
  config.site_identifiers = 'DDBIdentifier,HGVMetaIdentifier,HGVTransIdentifier,BiblioIdentifier,APISIdentifier'
  config.site_name = 'SoSOL'
  config.site_full_name = 'Son of Suda On Line'
  config.site_wiki_link = 'the <a href="http://idp.atlantides.org/trac/idp/wiki">Integrating Digital Papyrology wiki</a>'
  config.site_catalog_search = 'View in PN'
  config.site_email_from = 'admin@localhost'
  config.site_tag_line = 'powered by Son of Suda Online'
  config.site_user_namespace = 'http://data.perseus.org/users/'
  config.site_oac_namespace = 'http://data.perseus.org/annotations/sosoloacprototype'
  config.site_cite_collection_namespace ='http://data.perseus.org/collections'
end
