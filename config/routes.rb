ActionController::Routing::Routes.draw do |map|
  map.resources :communities, :member => { :find_member => :get, :add_member => :get, :add_member_page => :get, :remove_member => :get, :add_admin => :get, :add_admin_page => :get, :remove_admin => :get, :remove_current_user_membership => :post, :remove_current_user => :post } 

  #map.resources :glossaries
  map.resources :hgv_trans_glossaries, :member => { :update => :put }

  map.resources :emailers, :member => { :add_member => :get, :remove_member => :get} 

  map.resources :votes

  map.resources :decrees

  map.resources :docos

  map.resources :boards, :collection => { :rank => :get, :update_rankings => :post, :send_board_reminder_emails => :get } 
  map.resources :boards, :member => { :edit_members => :get, :add_member => :get, :remove_member => :get, :update_rankings => :post } 
 	
  map.resources :comments, :member => { :ask_for => :get }

  map.resources :events
  
  # map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  # map.login '/login', :controller => 'sessions', :action => 'new'
  # map.register '/register', :controller => 'users', :action => 'create'
  # map.signup '/signup', :controller => 'users', :action => 'new'
  map.resource :session
  
  map.help 'help', 
    :controller => 'user', 
    :action => 'help'
  
  map.build 'build', 
    :controller => 'docos', 
    :action => 'build'
  
  map.documentation 'documentation',
    :controller => "docos",
    :action => "documentation"

  #deletable map.connect 'articles/list_all', :controller => 'articles', :action => 'list_all'
  map.usage 'usage', :controller => 'user', :action => 'usage_stats'
  map.all_users_links 'all_users_links', :controller => 'user', :action => 'all_users_links'
  map.index_user_admins 'index_user_admins', :controller => 'user', :action => 'index_user_admins'
  map.dashboard 'dashboard', :controller => 'user', :action => 'dashboard'
  map.developer 'developer', :controller => 'user', :action => 'developer'
  map.sendmsg 'sendmsg', :controller => 'user', :action => 'create_email_everybody'

  #deleteable map.resources :articles, :member => { :review_for_finalize => :get, :comment_on => :get }

  map.master_list 'master_list', :controller => "publications", :action => "master_list"
  
  #deletable map.new_from_pn 'articles/new_from_pn', :controller => 'articles', :action => 'new_from_pn'
  #deletable map.begin_article  'articles/begin', :controller => 'articles', :action => 'begin'
  #map.connect 'articles/begin', :controller => 'articles', :action => 'begin'
  #deleteable map.resources :articles, :member => { :editxml => :get, :preview => :get, :comment_on => :get }
	
  map.connect 'publications/archive_all',
    :controller => 'publications',
    :action => 'archive_all',
    :conditions => { :method => :post }
    

  map.resources :publications, :collection => { :advanced_create => :get }
  map.resources :publications, :member => {  :edit_adjacent => :get, :edit_text => :get, :edit_meta => :get, :edit_apis => :get, :edit_biblio => :get, :edit_trans => :get, :show => :get, :create => :post, :create_from_templates => :post, :create_from_biblio_template => :post, :create_from_selector => :post, :submit => :post, :finalize_review => :get, :finalize => :post, :become_finalizer => :post }
  map.resources :publications do |publication|
    publication.resources :ddb_identifiers, :member => { :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put, :commentary => :get, :update_commentary => :put, :update_frontmatter_commentary => :put, :delete_commentary => :delete, :delete_frontmatter_commentary => :delete }
    publication.resources :hgv_meta_identifiers, :member => { :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put }
    publication.resources :apis_identifiers, :member => { :history => :get, :preview => :get, :xml => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put }
    publication.resources :hgv_trans_identifiers, :member => { :add_new_lang_to_xml => :post , :history => :get,  :preview => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put }
    publication.resources :biblio_identifiers, :member => { :history => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put, :preview => :get }

    publication.resources :epi_cts_identifiers, :member => { :history => :get, :preview => :get, :leiden => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put, :commentary => :get, :update_commentary => :put, :update_frontmatter_commentary => :put, :delete_commentary => :delete, :delete_frontmatter_commentary => :delete, :link_translation => :get, :link_citation => :get, :link_alignment => :post,  :annotate_xslt => :get }
    publication.resources :epi_trans_cts_identifiers, :member => { :history => :get,  :preview => :get, :editxml => :get, :edittext => :get, :updatetext => :put, :updatexml => :put, :rename_review => :get, :rename => :put, :create => :post, :link_citation => :get, :annotate_xslt => :get, :edit_title => :get, :update_title => :put}
    publication.resources :citation_cts_identifiers, :member => { :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put, :create => :get, :edit_or_create => :post, :select => :post, :annotate_xslt => :get}
    publication.resources :tei_cts_identifiers, :member => { :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :exportxml => :get, :rename_review => :get, :rename => :put, :commentary => :get, :update_commentary => :put, :update_frontmatter_commentary => :put, :delete_commentary => :delete, :delete_frontmatter_commentary => :delete, :link_translation => :get, :link_citation => :get , :annotate_xslt => :get}
    publication.resources :tei_trans_cts_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :exportxml => :get,:rename_review => :get, :rename => :put, :commentary => :get, :update_commentary => :put, :update_frontmatter_commentary => :put, :delete_commentary => :delete, :delete_frontmatter_commentary => :delete }
    publication.resources :cts_inventory_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :exportxml => :get,:rename_review => :get, :rename => :put, :commentary => :get, :update_commentary => :put, :update_frontmatter_commentary => :put, :delete_commentary => :delete, :delete_frontmatter_commentary => :delete }
    publication.resources :oac_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :exportxml => :get, :edit_or_create => :post, :append => :post, :rename_review => :get, :rename => :put, :edit => :post}
    publication.resources :cts_oac_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :annotate_xslt => :get, :editxml => :get, :updatexml => :put, :exportxml => :get, :edit_or_create => :post, :append => :post, :delete_annotation => :post }
    publication.resources :commentary_cite_identifiers, :member => { :create => :post, :create_from_annotation => :get, :history => :get, :preview => :get, :editxml => :get, :update => :put, :exportxml => :get, :edit => :post, :rename_review => :get, :rename => :put}
    publication.resources :treebank_cite_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :exportxml => :get, :edit => :post, :rename_review => :get, :rename => :put, :api_get => :get, :api_update => :post, :edit_title => :get, :update_title => :put}
    publication.resources :alignment_cite_identifiers, :member => { :create => :post, :create_from_annotation => :get, :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :exportxml => :get, :edit => :post, :rename_review => :get, :rename => :put, :api_get => :get, :api_update => :post, :edit_title => :get, :update_title => :put}
    publication.resources :oa_cite_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :annotate_xslt => :get, :editxml => :get, :import_update => :get, :updatexml => :put, :exportxml => :get, :edit_or_create => :post, :append => :post, :delete_annotation => :post, :update_from_agent => :post, :convert => :get, :rename_review => :get }
    publication.resources :oaj_cite_identifiers, :member => { :create => :post, :history => :get, :preview => :get, :edit => :post, :update => :put, :rename_review => :get }

    # publication.resources :identifiers
  end

  map.connect 'users/:user_name',
    :controller => 'user',
    :action => 'show',
    :user_name => /[^\/]*/
  
  map.connect 'publications/:publication_id/:controller/:id/show_commit/:commit_id',
    :controller => /.*_?identifiers/,
    :action => 'show_commit',
    :commit_id => /[0-9a-fA-F]{40}/
  
  map.connect 'publications/create_from_identifier/:id',
    :controller => 'publications',
    :action => 'create_from_identifier',
    :id => /papyri\.info.*/

  map.connect 'cts_publications/create_from_linked_urn/:urn',
    :controller => 'cts_publications',
    :action => 'create_from_linked_urn',
    :urn => /[^\/]*/

  map.connect 'cite_publications/user/:user_name/:identifier_type/:collection/:item_match',
    :controller => 'cite_publications',
    :action => 'user_collection_list',
    :conditions => { :method => :get },
    :user_name => /[^\/]*/,
    :identifier_type => /[^\/]*/,
    :collection => /[^\/]*/,
    :item_match => /[^\/]*/

  map.connect 'cite_publications/:identifier_type/:collection/:item_match',
    :controller => 'cite_publications',
    :action => 'user_collection_list',
    :conditions => { :method => :get },
    :identifier_type => /[^\/]*/,
    :collection => /[^\/]*/,
    :item_match => /[^\/]*/
        
  map.connect 'cite_publications/create_from_linked_urn/:type/:urn',
    :controller => 'cite_publications',
    :action => 'create_from_linked_urn',
    :type => /[^\/]*/,
    :urn => /[^\/]*/
  
  map.connect 'mulgara/sparql/:query',
    :controller => 'ajax_proxy',
    :action => 'sparql',
    :query => /.*/
   
  map.connect 'ajax_proxy/sparql/:query',
    :controller => 'ajax_proxy',
    :action => 'sparql',
    :query => /.*/
  
  map.connect 'ajax_proxy/xsugar/',
    :controller => 'ajax_proxy',
    :action => 'xsugar',
    :conditions => { :method => :post }
    
  map.connect 'ajax_proxy/hgvnum/',
    :controller => 'ajax_proxy',
    :action => 'hgvnum',
    :conditions => { :method => :post }
  
  map.connect 'ajax_proxy/:id',
    :controller => 'ajax_proxy',
    :action => 'proxy',
    :id => /papyri\.info.*/
   
  map.connect 'cts/editions/:inventory',
     :controller => 'cts_proxy',
     :action => 'editions',
     :inventory => /[^\/]*/
    
  map.connect 'cts/translations/:inventory/:urn',
     :controller => 'cts_proxy',
     :action => 'translations',
     :inventory => /[^\/]*/,
     :urn => /[^\/]*/
 
 map.connect 'cts/citations/:inventory/:urn',
     :controller => 'cts_proxy',
     :action => 'citations',
     :inventory => /[^\/]*/,
     :urn => /[^\/]*/
    
 map.connect 'cts/getpassage/:id/:urn',
     :controller => 'cts_proxy',
     :action => 'getpassage',
     :urn => /[^\/]*/
    
  map.connect 'cts/getcapabilities/:id',
     :controller => 'cts_proxy',
     :action => 'getcapabilities'

  map.connect 'cts/getrepos/:id',
    :controller => 'cts_proxy',
    :action => 'getrepos'
    
  map.connect 'shib/signin/:idp',
    :controller => 'shib',
    :action => 'signin'
    
  map.connect 'shib/metadata/:idp',
    :controller => 'shib',
    :action => 'metadata'
  
  map.connect 'dmm_api/item/:identifier_type/:id',
    :controller => 'dmm_api',
    :action => 'api_item_get',
    :conditions => { :method => :get }

  map.connect 'dmm_api/item/:identifier_type/:id',
    :controller => 'dmm_api',
    :action => 'api_item_patch',
    :conditions => { :method => :post }
    
  map.connect 'dmm_api/item/:identifier_type/:id/partial',
    :controller => 'dmm_api',
    :action => 'api_item_patch',
    :conditions => { :method => :post }
    
  map.connect 'dmm_api/item/:identifier_type/:id/partial',
    :controller => 'dmm_api',
    :action => 'api_item_get',
    :conditions => { :method => :get }
 
 map.connect 'dmm_api/item/:identifier_type/:id/append',
    :controller => 'dmm_api',
    :action => 'api_item_append',
    :conditions => { :method => :post }
 
 map.connect 'dmm_api/create/item/:identifier_type/:publication_id',
    :controller => 'dmm_api',
    :action => 'api_item_create',
    :conditions => { :method => :post },
    :publication_id => nil
 
 map.connect 'dmm_api/item/:identifier_type/:id/info/:format',
    :controller => 'dmm_api',
    :action => 'api_item_info',
    :conditions => { :method => :get },
    :format => nil
 
  map.connect 'dmm_api/item/:identifier_type/:id/return/:item_action',
    :controller => 'dmm_api',
    :action => 'api_item_return'

  map.connect 'dmm_api/item/:identifier_type/:id/comments',
    :controller => 'dmm_api',
    :action => 'api_item_comments_get',
    :conditions => { :method => :get }

  map.connect 'dmm_api/item/:identifier_type/:id/comments',
    :controller => 'dmm_api',
    :action => 'api_item_comments_post',
    :conditions => { :method => :post }

  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.signout 'signout',
    :controller => "user",
    :action => "signout"
    
  map.signin 'signin',
    :controller => "user",
    :action => "signin"

  map.terms 'terms',
    :controller => "user",
    :action => "terms"
    
  map.account 'account',
    :controller => "user",
    :action => "account"
end
