class OaCiteIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update]


  def import
    render :template => 'oa_cite_identifiers/import'
  end  

  def import_update
    find_identifier
    render :template => 'oa_cite_identifiers/import_update'
  end  

  def edit
    find_publication_and_identifier
    redirect_to @publication
  end

  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    render :template => 'oa_cite_identifiers/editxml'
  end

  def update_from_agent
    find_identifier
    params[:comment] ||= "Update from Agent #{params[:agent_url]}"
    begin
      updated_content =  @identifier.content_from_agent([params[:agent_url]])
      commit_sha = @identifier.set_xml_content(updated_content,
                                  :comment => params[:comment])
      if params[:comment] != nil && params[:comment].strip != ""
        @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment].to_s, :reason => "commit" } )
        @comment.save
      end
      flash[:notice] = "File updated."
      expire_publication_cache
      redirect_to @identifier.publication and return
    rescue Exception => import_error
      flash.now[:error] = "#{import_error}. This file was NOT UPDATED."
      render :template => 'oa_cite_identifiers/import_update'
    end
  end

  def create_from_annotation
    # there is no difference between create_from_annotation and 
    # create other than create_from_annotation supports GET 
    create()
  end 

  def create
    @publication = Publication.find(params[:publication_id].to_s)
    
    # use the default collection if one wasn't specified
    collection_urn = params[:urn] || Cite::CiteLib.get_default_collection_urn()
    valid_targets = params[:init_value]

    # required params: publication_id, urn, init_value
    unless (@publication && collection_urn)
      flash[:error] = "Unable to create item. Missing urn."
      redirect_to dashboard_url
      return
    end
    
    # make sure we have a valid collection 
    if Cite::CiteLib::get_collection(collection_urn).nil?
      flash[:error] = "Unable to create item. Unknown collection."
      redirect_to dashboard_url
      return
    end

    @identifier = OaCiteIdentifier.new_from_template(@publication,collection_urn,valid_targets)
    redirect_to polymorphic_path([@publication, @identifier],:action => :show)
  end

  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview
  end

  def convert
    find_identifier
    agent = AgentHelper::agent_of(params[:resource])
    if (agent.nil?)
      flash[:error] = "No agent for #{params[:resource]}"
      redirect_to dashboard_url
      return
    end
    agent_client = AgentHelper::get_client(agent)
    collection = AgentHelper::get_target_collection(agent,:OajCiteIdentifier)
    urn = Cite::CiteLib::object_uuid_urn(collection)
    uri = Sosol::Application.config.site_cite_collection_namespace + "/" + urn
    creator = url_for(:host => Sosol::Application.config.site_user_namespace, :controller => 'user', :action => 'show', :user_name => @identifier.publication.creator.name, :only_path => false)
    @converted = agent_client.get_content(params[:resource],uri,creator)
    if (@converted[:error]) 
      flash[:error] = "Conversion Failed!"
      respond_to do |format|
        format.json { render :json => @converted  }
        format.html { render :partial => "oajson" }
      end
    else 
      if params[:create]
        newobj = OajCiteIdentifier.new_from_supplied(@identifier.publication,urn,JSON.pretty_generate(@converted[:data]))
        flash[:notice] = "File created."
        expire_publication_cache
        redirect_to polymorphic_path([@identifier.publication, newobj],
                                 :action => :preview) and return
      else
        respond_to do |format|
          format.json { render :json => JSON.pretty_generate(@converted[:data]) }
          format.html { render :partial => "oajson" }
        end
      end
    end
  end
    
  protected
    def find_identifier
      @identifier = OaCiteIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end
  
end

