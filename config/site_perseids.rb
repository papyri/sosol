# Used for Site specific overrides
Sosol::Application.configure do
  config.site_identifiers = 'CitationCTSIdentifier,EpiCTSIdentifier,EpiTransCTSIdentifier,CTSInventoryIdentifier,OACIdentifier,CommentaryCiteIdentifier,TreebankCiteIdentifier,AlignmentCiteIdentifier,OaCiteIdentifier,OajCiteIdentifier,'
  config.site_name = 'Perseids'
  config.site_full_name = 'Perseids'
  config.site_wiki_link = '<a href="http://sites.tufts.edu/perseids">Perseids Blog and Documentation</a>.'
  config.site_catalog_search = 'View in Catalog'
  config.site_email_from = 'admin@localhost'
  config.site_tag_line = 'powered by Son of Suda Online'
  config.site_user_namespace = 'http://data.perseus.org/sosol/users/'
  config.site_oac_namespace = 'http://data.perseus.org/annotations/sosoloacprototype'
  config.site_cite_collection_namespace ='http://data.perseus.org/collections'
  config.repository_root = "/usr/local/gitrepos"
  config.canonical_repository = File.join(config.repository_root, 'canonical.git')
  config.site_cookie_domain = '.perseids.org'
  config.site_cookie_expire_minutes = 60
end
