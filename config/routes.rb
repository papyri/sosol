Sosol::Application.routes.draw do
  resources :communities do
  
    member do
  get :find_member
  get :add_member
  get :add_member_page
  get :remove_member
  get :add_admin
  get :add_admin_page
  get :remove_admin
  post :remove_current_user_membership
  post :remove_current_user
  end
  
  end

  resources :hgv_trans_glossaries do
  
    member do
  patch :update
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
  end
  
  end

  resources :events
  resource :session
  match 'help' => 'user#help', :as => :help, :via => :get
  match 'usage' => 'user#usage_stats', :as => :usage, :via => :get
  match 'all_users_links' => 'user#all_users_links', :as => :all_users_links, :via => :get
  match 'index_user_admins' => 'user#index_user_admins', :as => :index_user_admins, :via => :get
  match 'dashboard' => 'user#dashboard', :as => :dashboard, :via => :get
  match 'developer' => 'user#developer', :as => :developer, :via => :get
  match 'sendmsg' => 'user#create_email_everybody', :as => :sendmsg, :via => :get
  match 'master_list' => 'publications#master_list', :as => :master_list, :via => :get
  match 'publications/archive_all' => 'publications#archive_all', :via => :post
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
    patch :updatexml
    get :rename_review
    patch :rename
    get :commentary
    patch :update_commentary
    patch :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    end
    
    end

    resources :hgv_meta_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    end
    
    end

    resources :dclp_meta_identifiers do

        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    end

    end

    resources :dclp_text_identifiers do

        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    get :commentary
    patch :update_commentary
    patch :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    end

    end

    resources :apis_identifiers do
    
        member do
    get :history
    get :preview
    get :xml
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    end
    
    end

    resources :hgv_trans_identifiers do
    
        member do
    post :add_new_lang_to_xml
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    end
    
    end

    resources :biblio_identifiers do
    
        member do
    get :history
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    get :preview
    end
    
    end

    resources :epi_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    get :commentary
    patch :update_commentary
    patch :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    get :link_translation
    end
    
    end

    resources :epi_trans_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    post :create
    end
    
    end

    resources :citation_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :rename_review
    patch :rename
    get :create
    post :edit_or_create
    post :select
    end
    
    end

    resources :tei_cts_identifiers do
    
        member do
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :exportxml
    get :rename_review
    patch :rename
    get :commentary
    patch :update_commentary
    patch :update_frontmatter_commentary
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
    patch :updatexml
    get :exportxml
    get :rename_review
    patch :rename
    get :commentary
    patch :update_commentary
    patch :update_frontmatter_commentary
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
    patch :updatexml
    get :exportxml
    get :rename_review
    patch :rename
    get :commentary
    patch :update_commentary
    patch :update_frontmatter_commentary
    delete :delete_commentary
    delete :delete_frontmatter_commentary
    end
    
    end

    resources :oac_identifiers do
    
        member do
    post :create
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :exportxml
    post :edit_or_create
    post :append
    get :rename_review
    patch :rename
    end
    
    end

    resources :cts_oac_identifiers do
    
        member do
    post :create
    get :history
    get :preview
    get :editxml
    patch :updatexml
    get :exportxml
    post :edit_or_create
    post :append
    patch :delete_annotation
    end
    
    end
  end

  get 'documentation' => redirect('http://papyri.info/docs/leiden_plus')
  match 'users/:user_name' => 'user#show', :user_name => /[^\/]*/, :via => :get
  match 'peep_user_dashboard/:user_id(/:publication)' => 'user#peep_user_dashboard', :user_id => /\d+/, :publication => /(submitted|editing|new|committed|finalizing|\d+)/, :via => :get
  match 'editor/user/info' => 'user#info', :via => :get
  %w{apis biblio citation_cts collection cts_inventory cts_oac dclp_meta dclp_text ddb epi_cts epi_trans_cts hgv_meta hgv_trans oac tei_cts tei_trans_cts}.each do |identifier_class|
    match 'publications/:publication_id/:identifier_controller/:id/show_commit/:commit_id', controller: "#{identifier_class}_identifiers", action: :show_commit, constraints: { :commit_id => /[0-9a-fA-F]{40}/, :identifier_controller => /#{identifier_class}_identifiers/ }, :via => :get
  end
  match 'publications/create_from_identifier/:id' => 'publications#create_from_identifier', :id => /papyri\.info.*/, :via => :get
  match 'publications/vote/:id' => 'publications#vote', :via => :post
  match 'cts_publications/create_from_linked_urn/:urn' => 'cts_publications#create_from_linked_urn', :urn => /[^\/]*/, :via => :get
  match 'js/:query' => 'ajax_proxy#js', :query => /.*/, :via => :get
  match 'css/:query' => 'ajax_proxy#css', :query => /.*/, :via => :get
  match 'images/:query' => 'ajax_proxy#images', :query => /.*/, :via => :get
  match 'mulgara/sparql/:query' => 'ajax_proxy#sparql', :query => /.*/, :via => :get
  match 'ajax_proxy/sparql/:query' => 'ajax_proxy#sparql', :query => /.*/, :via => :get
  match 'sparql' => 'ajax_proxy#sparql', :via => :get
  match 'ajax_proxy/xsugar/' => 'ajax_proxy#xsugar', :via => :post
  match 'ajax_proxy/hgvnum/' => 'ajax_proxy#hgvnum', :via => :post
  match 'ajax_proxy/:id' => 'ajax_proxy#proxy', :id => /papyri\.info.*/, :via => :get
  match 'cts/editions/:inventory' => 'cts_proxy#editions', :inventory => /[^\/]*/, :via => :get
  match 'cts/translations/:inventory/:urn' => 'cts_proxy#translations', :inventory => /[^\/]*/, :urn => /[^\/]*/, :via => :get
  match 'cts/citations/:inventory/:urn' => 'cts_proxy#citations', :inventory => /[^\/]*/, :urn => /[^\/]*/, :via => :get
  match 'cts/getpassage/:id/:urn' => 'cts_proxy#getpassage', :urn => /[^\/]*/, :via => :get
  match 'cts/getcapabilities/:collection' => 'cts_proxy#getcapabilities', :via => :get
  match 'cts/getrepos' => 'cts_proxy#getrepos', :via => :get
  match '/' => 'welcome#index', :via => :get
  match '/:controller(/:action(/:id))', :via => :get
  match 'signout' => 'user#signout', :as => :signout, :via => :get
  match 'signin' => 'user#signin', :as => :signin, :via => :get
  match 'account' => 'user#account', :as => :account, :via => :get
  post 'rpx/login_return', to: 'rpx#login_return'
  post 'rpx/remove_openid', to: 'rpx#remove_openid'
  post 'rpx/associate_return', to: 'rpx#associate_return'
  post 'rpx/associate_really', to: 'rpx#associate_really'
  post 'rpx/create_submit', to: 'rpx#create_submit'
  post 'identifiers/create', to: 'identifiers#create'
  get 'user/board_dashboard', to: 'user#board_dashboard'
  get 'user/user_community_dashboard', to: 'user#user_community_dashboard'
  get 'user/user_complete_dashbaord', to: 'user#user_complete_dashbaord'
  get 'user/archives', to: 'user#archives'
  get 'user/admin', to: 'user#admin'
  get 'user/edit_user_admins', to: 'user#edit_user_admins'
  get 'user/download_by_status', to: 'user#download_by_status'
  get 'user/download_user_publications', to: 'user#download_user_publications'
  get 'user/download_options', to: 'user#download_options'
  patch 'user/update_personal', to: 'user#update_personal'
  patch 'user/update_admins', to: 'user#update_admins'
  match 'user/email_everybody' => 'user#email_everybody', via: [:patch, :post]
  match 'user/refresh_usage' => 'user#refresh_usage', via: [:patch, :post]
  match 'user/leave_community' => 'user#leave_community', via: [:patch, :post]
  get 'cross_site/footer', to: 'cross_site#footer'
  get 'cross_site/header', to: 'cross_site#header'
  get 'cross_site/advanced_create', to: 'cross_site#advanced_create'
  get 'cross_site/sign_in_out', to: 'cross_site#sign_in_out'
  get 'helper/ancientdia', to: 'helper#ancientdia'
  get 'helper/number', to: 'helper#number'
  get 'helper/gapall', to: 'helper#gapall'
  get 'helper/insertFootnote', to: 'helper#insertFootnote'
  get 'helper/insertLinkBiblio', to: 'helper#insertLinkBiblio'
  get 'helper/insertLinkPN', to: 'helper#insertLinkPN'
  get 'helper/insertlink', to: 'helper#insertlink'
  get 'helper/abbrev', to: 'helper#abbrev'
  get 'helper/appalt', to: 'helper#appalt'
  get 'helper/appBL', to: 'helper#appBL'
  get 'helper/appcorr', to: 'helper#appcorr'
  get 'helper/appedit', to: 'helper#appedit'
  get 'helper/appSoSOL', to: 'helper#appSoSOL'
  get 'helper/appreg', to: 'helper#appreg'
  get 'helper/appsubst', to: 'helper#appsubst'
  get 'helper/division', to: 'helper#division'
  get 'helper/tryit', to: 'helper#tryit'
  get 'translation_helper/terms', to: 'translation_helper#terms'
  get 'translation_helper/new_lang', to: 'translation_helper#new_lang'
  get 'translation_helper/linebreak', to: 'translation_helper#linebreak'
  get 'translation_helper/division', to: 'translation_helper#division'
  get 'translation_helper/tryit', to: 'translation_helper#tryit'
end
