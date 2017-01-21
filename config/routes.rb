Sosol::Application.routes.draw do
  use_doorkeeper do
    controllers :applications => 'api_clients'
  end

  resources :apidocs, only: [:index]

  root :to => 'welcome#index'

  namespace :api do
    namespace :v1 do
      resources :items do
        member do
          get :peek
        end
      end
      resources :publications do
        member do
          post :submit
        end
      end
      resources :communities do
        member do
          get :index
        end
      end
      match 'user', to: 'api#user', via: [:get]
      match '*all' => 'api#preflight_check', :via => :options
      match 'xmlitems/:identifier_type' =>'xml_items#create', :via => :post
      get 'terms' => 'api#terms' 
      get 'license' => 'api#license'
      get 'contact' => 'api#contact'
      get 'export_ro' => 'api#export_ro'
    end
  end

  resources :pass_through_communities do
    member do
      get :confirm_destroy
    end
  end

  resources :end_user_communities do
    member do
      get :confirm_destroy
    end
  end

  resources :master_communities do
    member do
      get :confirm_destroy
    end
  end

  match 'communities/select_default' => 'communities#select_default'
  match 'communities/change_default' => 'communities#change_default', :via => :post

  resources :communities do
  
    member do
  get :find_member
  get :add_member
  get :add_member_page
  get :remove_member
  get :add_admin
  get :add_admin_page
  get :remove_admin
  get :confirm_destroy
  post :remove_current_user_membership
  post :remove_current_user
  end
  
  end

  resources :hgv_trans_glossaries do
  
    member do
  put :update
  end
  
  end

  resources :emailers do
  
    member do
  get :add_member
  get :remove_member
  end
  
  end

  resources :votes
  resources :decrees
  resources :docos
  resources :boards do
    collection do
  get :rank
  post :update_rankings
  get :send_board_reminder_emails
  end
  
  
  end

  resources :boards do
    member do
  get :edit_members
  get :add_member
  get :remove_member
  post :update_rankings
  end
  end

  resources :comments do
    member do
  get :ask_for
  get :edittext
  end

  end

  resources :events
  resource :session
  match 'help' => 'user#help', :as => :help
  match 'build' => 'docos#build', :as => :build
  match 'documentation' => 'docos#documentation', :as => :documentation
  match 'usage' => 'user#usage_stats', :as => :usage
  match 'all_users_links' => 'user#all_users_links', :as => :all_users_links
  match 'index_user_admins' => 'user#index_user_admins', :as => :index_user_admins
  match 'dashboard' => 'user#dashboard', :as => :dashboard
  match 'developer' => 'user#developer', :as => :developer
  match 'sendmsg' => 'user#create_email_everybody', :as => :sendmsg
  match 'master_list' => 'publications#master_list', :as => :master_list
  match 'publications/archive_all' => 'publications#archive_all', :via => :post
  match 'export_options' => 'user#export_options'
  resources :publications do
    collection do
  get :advanced_create
  end
  
  
  end

  resources :publications do
  
    member do
  get :edit_adjacent
  get :edit_text
  get :edit_meta
  get :edit_apis
  get :edit_biblio
  get :edit_trans
  get :show
  post :submit
  get :finalize_review
  post :finalize
  post :become_finalizer
  get  :become_finalizer
  post :assign_finalizer
  get :agent_failure_callback
  get :send_to_agent
  end
  end
  post 'publications/create' => 'publications#create'
  post 'publications/create_from_templates' => 'publications#create_from_templates'
  post 'publications/create_from_biblio_template' => 'publications#create_from_biblio_template'
  post 'publications/create_from_selector' => 'publications#create_from_selector'
  

  resources :publications do
  
  
      resources :ddb_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    get :commentary
    put :update_commentary
    put :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    end
    
    end

    resources :hgv_meta_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    end
    
    end

    resources :apis_identifiers do
    
        member do
    get :history
    get :preview
    get :xml
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    end
    
    end

    resources :hgv_trans_identifiers do
    
        member do
    post :add_new_lang_to_xml
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    end
    
    end

    resources :biblio_identifiers do
    
        member do
    get :history
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    get :preview
    end
    
    end

    resources :epi_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :leiden
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    get :commentary
    put :update_commentary
    put :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    get :link_translation
    get :link_citation
    get :annotate_xslt
    end
    
    end

    resources :epi_trans_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    get :edittext
    put :updatexml
    put :updatetext
    get :rename_review
    put :rename
    post :create
    get :link_citation
    get :annotate_xslt
    get :edit_title
    put :update_title
    end
    
    end

    resources :citation_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :rename_review
    put :rename
    get :create
    post :edit_or_create
    post :select
    get :annotate_xslt
    end
    
    end

    resources :tei_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :exportxml
    get :rename_review
    put :rename
    get :commentary
    put :update_commentary
    put :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    get :link_translation
    get :link_citation
    end
    
    end

    resources :tei_trans_cts_identifiers do
    
        member do
    post :create
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :exportxml
    get :rename_review
    put :rename
    get :commentary
    put :update_commentary
    put :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    end
    
    end

    resources :cts_inventory_identifiers do
    
        member do
    post :create
    get :history
    get :preview
    get :editxml
    put :updatexml
    get :exportxml
    get :rename_review
    put :rename
    get :commentary
    put :update_commentary
    put :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    end
    
    end

    resources :treebank_cite_identifiers do
        member do
    post :create
    get :history 
    get :preview 
    get :editxml 
    put :updatexml
    get :exportxml 
    post :edit 
    get :rename_review
    put :rename
    get :api_get
    post :api_update 
    get :edit_title
    get :compare
    get :review
    put :update_title
    end
    end

    resources :alignment_cite_identifiers do
        member do
    post :create
    get :history 
    get :preview 
    get :editxml 
    put :updatexml
    get :exportxml 
    post :edit
    get :rename_review
    put :rename
    get :api_get
    post :api_update 
    get :edit_title
    put :update_title
    end
    
    end
    resources :commentary_cite_identifiers do 
        member do
    post :create 
    get :create_from_annotation
    get :history 
    get :preview 
    get :editxml 
    put :update 
    get :exportxml
    post :edit 
    get :rename_review 
    put :rename
    end
    end
    
    resources :oa_cite_identifiers do 
      member do
      post :create 
      get :history
      get :preview 
      get :annotate_xslt 
      get :editxml
      get :import_update 
      put :updatexml
      get :exportxml 
      post :edit_or_create 
      post :append 
      post :delete_annotation 
      put :update_from_agent
      get :convert
      get :rename_review 
    end
    end

    resources :oaj_cite_identifiers do
      member do
      post :create 
      get :history 
      get :preview
      post :edit 
      put :update
      get :rename_review
    end
    end

    resources :syriaca_identifiers do
    
      member do
        get :history
        get :raw_preview
        get :preview
        get :editxml
        get :rename_review
        put :updatexml
      end
    end

    resources :syriaca_person_identifiers do
    
      member do
        get :history
        get :raw_preview
        get :preview
        get :editxml
        get :rename_review
        put :updatexml
      end
    end

    # the cts_oac_identifier resource model is deprecated
    resources :cts_oac_identifiers do
    
      member do
        get :history
        get :preview
        get :editxml
        put :updatexml
        get :exportxml
        post :append
        post :delete_annotation
        get :annotate_xslt
      end
    end
    # the oac_identifier resource model is deprecated
    resources :oac_identifiers do
      member do
        get :history
        get :preview
        get :editxml
        put :updatexml
        get :exportxml
        post :append
        get :rename_review
        put :rename
      end
    end

    # the tei_cts_identifier model is deprecated
    resources :tei_cts_identifiers do
    
      member do
        get :history
        get :preview
      end
    end

    # the tei_trans_cts_identifier model is deprecated
    resources :tei_trans_cts_identifiers do
      member do
        get :history
        get :preview
      end
    end

  end

  match 'users/:user_name' => 'user#show', :user_name => /[^\/]*/
  match 'editor/user/info' => 'user#info'
  match 'publications/:publication_id/:controller/:id/show_commit/:commit_id' => '(?-mix:.*_?identifiers)#show_commit', :commit_id => /[0-9a-fA-F]{40}/
  match 'publications/create_from_identifier/:id' => 'publications#create_from_identifier', :id => /papyri\.info.*/
  match 'cts_publications/create_from_linked_urn/:urn' => 'cts_publications#create_from_linked_urn', :urn => /[^\/]*/
  match 'cite_publications/:identifier_type/:collection/:item_match' => 'cite_publications#user_collection_list', :identifier_type => /TreebankCite|AlignmentCite|CommentaryCite|OajCite|OaCite/,  :collection => /[^\/]*/, :item_match => /[^\/]*/
  match 'cite_publications/user/:user_name/:identifier_type/:collection/:item_match' => 'cite_publications#user_collection_list', :identifier_type => /TreebankCite|AlignmentCite|CommentaryCite|OajCite|OaCite/,  :collection => /[^\/]*/, :item_match => /[^\/]*/, :user_name => /[^\/]*/
  match 'cite_publications/create_from_linked_urn/:identifier_type/:urn' => 'cite_publications#create_from_linked_urn', :urn => /[^\/]*/, :identifier_type => /[^\/]*/
  match 'js/:query' => 'ajax_proxy#js', :query => /.*/
  match 'css/:query' => 'ajax_proxy#css', :query => /.*/
  match 'images/:query' => 'ajax_proxy#images', :query => /.*/
  match 'mulgara/sparql/:query' => 'ajax_proxy#sparql', :query => /.*/
  match 'ajax_proxy/sparql/:query' => 'ajax_proxy#sparql', :query => /.*/
  match 'sparql' => 'ajax_proxy#sparql'
  match 'ajax_proxy/xsugar/' => 'ajax_proxy#xsugar', :via => :post
  match 'ajax_proxy/hgvnum/' => 'ajax_proxy#hgvnum', :via => :post
  match 'ajax_proxy/:id' => 'ajax_proxy#proxy', :id => /papyri\.info.*/
  match 'cts/editions/:inventory' => 'cts_proxy#editions', :inventory => /[^\/]*/
  match 'cts/translations/:inventory/:urn' => 'cts_proxy#translations', :inventory => /[^\/]*/, :urn => /[^\/]*/
  match 'cts/citations/:inventory/:urn' => 'cts_proxy#citations', :inventory => /[^\/]*/, :urn => /[^\/]*/
  match 'cts/getpassage/:id/:urn' => 'cts_proxy#getpassage', :urn => /[^\/]*/
  match 'cts/getcapabilities/:id' => 'cts_proxy#getcapabilities'
  match 'cts/getrepos/:id' => 'cts_proxy#getrepos'
  match 'shib/signin/:idp' => 'shib#signin'
  match 'shib/metadata/:idp' => 'shib#metadata'
  match 'dmm_api/*all' => 'dmm_api#preflight_check', :via => :options
  match 'dmm_api/item/:identifier_type/:id' =>'dmm_api#api_item_get', :via => :get
  match 'dmm_api/item/:identifier_type/:id' => 'dmm_api#api_item_patch', :via => :post
  match 'dmm_api/item/:identifier_type/:id/partial' => 'dmm_api#api_item_patch', :via => :post
  match 'dmm_api/item/:identifier_type/:id/partial' => 'dmm_api#api_item_get', :via => :get
  match 'dmm_api/item/:identifier_type/:id/append' => 'dmm_api#api_item_append', :via => :post
  match 'dmm_api/create/item/:identifier_type(/:publication_id)' => 'dmm_api#api_item_create', :via => :post
  match 'dmm_api/item/:identifier_type/:id/info(/:format)' => 'dmm_api#api_item_info', :via => :get
  match 'dmm_api/item/:identifier_type/:id/return/:item_action' => 'dmm_api#api_item_return'
  match 'dmm_api/item/:identifier_type/:id/comments' => 'dmm_api#api_item_comments_get', :via => :get
  match 'dmm_api/item/:identifier_type/:id/comments' => 'dmm_api#api_item_comments_post', :via => :post
  match 'dmm_api/ping' => 'dmm_api#ping', :via => :get

  match '/' => 'welcome#index'
  match '/:controller(/:action(/:id))'
  match 'signout' => 'user#signout', :as => :signout
  match 'signin' => 'user#signin', :as => :signin
  match 'account' => 'user#account', :as => :account
  
end
