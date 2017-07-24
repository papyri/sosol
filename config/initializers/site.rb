# This is where we configure site specific details
Sosol::Application.configure do
  config.site_layout = 'pn'
  config.site_name = 'SoSOL'
  config.site_full_name = 'Son of Suda On Line'
  config.site_wiki_link = 'the <a href="http://idp.atlantides.org/trac/idp/wiki">Integrating Digital Papyrology wiki</a>'
  config.site_catalog_search = 'View in PN'
  config.site_email_from = 'admin@localhost'
  config.site_tag_line = ''
  config.site_user_namespace = 'http://papyri.info'
  config.site_oac_namespace = ''
  config.site_cite_collection_namespace ='http://data.perseus.org/collections'
  config.site_cookie_domain = 'localhost'
  config.site_cookie_expire_minutes = 60
  config.current_terms_version = 0
  config.site_show_community_pubs=true
  config.site_show_assigned_pubs=true
  config.site_show_events=true
  config.site_keep_comments=true
end
