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
  config.site_show_community_pubs=false
  config.site_show_assigned_pubs=false
  config.site_hide_events=false
  config.site_keep_comments=false

  # Example Perseids Configuration
  # config.site_layout = 'perseids'
  # config.site_name = 'Perseids'
  # config.site_full_name = 'Perseids'
  # config.site_wiki_link = '<a href="http://sites.tufts.edu/perseids" target="_blank">Read More</a>'
  # config.site_catalog_search = 'View in Catalog'
  # config.site_email_from = 'perseids@localhost'
  # config.site_tag_line = 'powered by Son of Suda Online'
  # config.site_user_namespace = 'http://data.perseus.org/sosol/users/'
  # config.site_oac_namespace = 'http://data.perseus.org/annotations/sosoloacprototype'
  # config.site_cite_collection_namespace ='http://data.perseus.org/collections'
  # config.site_cookie_domain = 'localhost'
  # config.site_cookie_expire_minutes = 60
  # config.site_show_community_pubs=true
  # config.site_show_assigned_pubs=true
  # config.site_hide_events=true
  # config.site_keep_comments=true
  # config.site_views = 'app/views_perseids'
  # config.site_identifiers = 'CitationCTSIdentifier,EpiCTSIdentifier,EpiTransCTSIdentifier,CTSInventoryIdentifier,OACIdentifier,CommentaryCiteIdentifier,TreebankCiteIdentifier,AlignmentCiteIdentifier,OaCiteIdentifier,OajCiteIdentifier,SyriacaIdentifier,SyriacaPersonIdentifier,SyriacaWorkIdentifier'
  # config.site_pubs_link = '<a href="http://sites.tufts.edu/perseids/publications/student-publications" target="_blank">Sample Publications </a>'
  # config.site_instructions_link = '<a href="http://sites.tufts.edu/perseids/instructions/" target="_blank">Instructions</a>'
  # config.terms_text="<h2>Perseids Terms of Service</h2><p>By using Perseids (\"www.perseids.org\" or \"perseids.org\") and its affiliated sites and tools, you are agreeing to the following terms and conditions (\"terms of service\"). No rights or benefits are conferred by these terms, and they may be updated at any time. If you do not agree to these terms, please do not use the service. The Perseids Projects collects usernames, names, and email addresses from its users in order to provide our software to users. The Perseids Project is established at Tufts University, located in the United States of America. Users in the European Economic Area can find more information about Tufts’ personal data use practices at www.tufts.edu/about/privacy. </p><ol>  <li>    General Conditions    <ol>      <li>This service is provided \"as is\" and on an \"as available basis.\" No warranty is implied. No liability is assumed by Perseids, its creators, or host institutions.</li>      <li>You must be 13 years or older to use Perseids. (Please also see \"Privacy\" below.)</li>      <li>You agree not to use the Perseids service for malicious, illegal, or abusive behavior. Such behavior will be determined at the sole discretion of the Perseids advisory board and result in account suspension or termination.</li>      <li>Further, you agree to obey all laws in your jurisdiction regarding copyrighted material. Perseids assumes no responsibility for misuse of this service to distribute copyrighted materials and reserves the right to immediately remove materials suspected of violating copyright laws and suspend access during any account review. In the case of disputed materials, Perseids will follow US copyright laws unless otherwise noted.</li>    </ol>  </li>  <li>    Account Creation and Deletion    <ol>      <li>You may operate multiple accounts on Perseids or use shared accounts. (Note that any abuse associated with a shared account may result in the suspension or termination of all users associated with said shared account.)</li>      <li>Anonymous accounts are not permitted. </li>      <li>Deletion of an account requires an email to perseids \"at\" tufts.edu.</li>      <li>Use of Perseids requires the creation of a publicly viewable nickname. The Perseids advisory board reserves the sole right to reject obscene, offensive, or otherwise inappropriate user nicknames. Repeated creation of accounts with rejected nicknames will result in users being denied access to the service.</li>    </ol>  </li>  <li>    Content, Data and Copyright    <ol>      <li>You understand that all data in Perseids is freely available to users and the public while it remains on the platform. You are free to download your data at any time. </li>      <li>You control \"pre-publication data.\" \"Pre-publication data\" is defined as data or materials that have not been submitted to the Perseids master board or otherwise submitted for publication. You are free to delete this data at any time prior to publication. \"Pre-publication\" data may be preserved in backups for up to one year, but Perseids makes no guarantee of recoverability once this data has been deleted.</li>      <li>Once you agree to publish your data, you agree to do so under a Creative Commons CC-BY-SA license. Publication is defined as submission to the Perseids master board, or a process otherwise labeled or identified as resulting in the same end result.</li>      <li>Perseids will make reasonable efforts to store and backup data published in the platform for a minimum term of five years following the conclusion of Phase One of the project (December 31, 2020). </li>      <li>Perseids may use third party services or software to accomplish data or content management, including cloud services.</li>  <li>    Privacy    <ol>      <li>        You must agree to provide the following information to Perseids in order to use the service:        <ol>          <li>a user nickname which will be made publicly available. (Please refer to 2.d. above on nickname review.)</li>          <li>a user identifier for login purposes, such as an institutional identity provider or social login.</li>        </ol>      </li>      <li>        You may wish to provide optional information such as:        <ol>          <li>email address for service updates and notifications</li>          <li>a full name</li>          <li>affiliation or institution</li>        </ol>      </li>      <li>Perseids uses OpenID, OAuth, and SAML2 protocols to interoperate with identity providers for login. </li>      <li>No passwords are seen by or retained by Perseids.</li>      <li>Email is not shared publicly or otherwise redistributed to external parties.</li>      <li>Full name and affiliation may be displayed in certain applications and will be viewable to other Perseids users.</li>      <li>        Perseids does use a cookie for session management and some information may be stored in the browser's local storage cache.         <ol>          <li>Arethusa stores application setting preferences, morphological forms created, and morphological forms selected.</li>         </ol>      </li>    </ol>  </li>  <li>    Special considerations for users under the age of 18    <ol>      <li>Please use Perseids in consultation with a parent, guardian, instructor, or teacher.</li>      <li>        Please note:        <ol>          <li>What you do in Perseids will be seen by others.</li>          <li>What you do in Perseids will be saved.</li>          <li>Please be respectful of other people's work. Do not use materials from books, journals, or other web sites unless you have permission to do so.</li>          <li>Please be respectful of other users. </li>          <li>Do not reveal any information about yourself you do not want others to see. You may use a nickname for your Perseids work. You do not have to use your full name or enter other information (unless your teacher instructs otherwise). </li>          <li>Perseids will not send information about you to anyone else.</li>        </ol>      </li>      <li>If you do not understand any of these terms or conditions please contact Perseids at perseids \"at\" tufts.edu and we will answer your specific questions.</li><p>Last Updated: June 5, 2015</p><p>perseids \"at\" tufts.edu</p>"
  # config.current_terms_version = 1
  # config.site_api_title="Perseids API"
  # config.site_api_description="The Perseids API is currently in Alpha mode and intended for testing by registered partners only."
  # config.site_api_terms='config/initializers/site.terms.erb'
  # config.site_api_license_name="Perseids API License"
  # config.site_api_contact_email="perseids@tufts.edu"
  # config.site_api_contact_name="Bridget Almas, The Perseids Project, Perseus Digital Library, Tufts University"
  # config.action_mailer.default_url_options= { host: 'sosol.perseids.org/sosol', protocol: 'https' }
end
