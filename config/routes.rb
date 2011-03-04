ActionController::Routing::Routes.draw do |map|
  #map.resources :glossaries
  map.resources :hgv_trans_glossaries, :member => { :update => :put }

  map.resources :emailers, :member => { :add_member => :get, :remove_member => :get} 

  map.resources :votes

  map.resources :decrees

  map.resources :docos

  map.resources :boards, :collection => { :rank => :get, :update_rankings => :post } 
  map.resources :boards, :member => { :edit_members => :get, :add_member => :get, :remove_member => :get, :update_rankings => :post } 
  
 
  map.resources :users
 	
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
  map.dashboard 'dashboard', :controller => 'user', :action => 'dashboard'
  map.developer 'developer', :controller => 'user', :action => 'developer'
  map.sendmsg 'sendmsg', :controller => 'user', :action => 'create_email_everybody'
 
  #deleteable map.resources :articles, :member => { :review_for_finalize => :get, :comment_on => :get }

  map.master_list 'master_list', :controller => "publications", :action => "master_list"
  
  #deletable map.new_from_pn 'articles/new_from_pn', :controller => 'articles', :action => 'new_from_pn'
  #deletable map.begin_article  'articles/begin', :controller => 'articles', :action => 'begin'
  #map.connect 'articles/begin', :controller => 'articles', :action => 'begin'
  #deleteable map.resources :articles, :member => { :editxml => :get, :preview => :get, :comment_on => :get }
	
  map.resources :publications, :collection => { :advanced_create => :get }
  map.resources :publications, :member => {  :edit_adjacent => :get, :edit_text => :get, :edit_meta => :get, :edit_biblio => :get, :edit_trans => :get, :show => :get, :create => :post, :create_from_templates => :post, :create_from_selector => :post, :submit => :post, :finalize_review => :get, :finalize => :post, :become_finalizer => :post }
  map.resources :publications do |publication|
    publication.resources :ddb_identifiers, :member => { :history => :get, :preview => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put, :commentary => :get, :update_commentary => :put, :delete_commentary => :delete }
    publication.resources :hgv_meta_identifiers, :member => { :history => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put }
    publication.resources :hgv_biblio_identifiers, :member => { :history => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put }
    publication.resources :hgv_trans_identifiers, :member => { :add_new_lang_to_xml => :post , :history => :get,  :preview => :get, :editxml => :get, :updatexml => :put, :rename_review => :get, :rename => :put }
    # publication.resources :identifiers
  end
  
  map.connect 'publications/:publication_id/:controller/:id/show_commit/:commit_id',
    :controller => /.*_?identifiers/,
    :action => 'show_commit',
    :commit_id => /[0-9a-fA-F]{40}/
  
  map.connect 'publications/create_from_identifier/:id',
    :controller => 'publications',
    :action => 'create_from_identifier',
    :id => /papyri\.info.*/
  
  map.connect 'numbers_server_proxy/sparql/:query',
    :controller => 'numbers_server_proxy',
    :action => 'sparql',
    :query => /.*/
  
  map.connect 'numbers_server_proxy/:id',
    :controller => 'numbers_server_proxy',
    :action => 'proxy',
    :id => /papyri\.info.*/
  
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
    
  map.account 'account',
    :controller => "user",
    :action => "account"
end
