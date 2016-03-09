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
    annotation_uri = params[:annotation_uri]
    if (annotation_uri)
      editor_url = Tools::Manager.link_to('oa_editor',:perseids,:edit,[@identifier])[:href]
      editor_url = editor_url.sub(/URI/,URI.escape(annotation_uri))
      redirect_to(editor_url) and return
    end
    @list = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite oa_cite_preview.xsl})),
        { :tool_url => Tools::Manager.link_to('oa_editor',:perseids,:edit,[@identifier])[:href],
          :mode => 'edit',
          :lang => 'grc', # TODO PULL FROM ANNOTATION TEXT
          :delete_link => url_for(:controller => 'oa_cite_identifiers', :action => 'delete_annotation', :publication_id => @identifier.publication.id, :id => @identifier.id),
          :align_link => url_for(:controller => 'alignment_cite_identifiers', :publication_id => @identifier.publication.id.to_s, :a_id => @identifier.id.to_s, :action => :create_from_annotation),
          :app_base => root_url,
          :form_token => form_authenticity_token 
        })
  end

  def delete_annotation 
    find_publication_and_identifier
    annotation_uri = params[:annotation_uri]
    annotation = @identifier.get_annotation(annotation_uri)
    if (annotation.nil?)
      flash[:error] = "Annotation #{annotation_uri} not found"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    end
    @identifier.delete_annotation(annotation_uri,"Deleted Annotation #{annotation_uri}")
    flash[:notice] = "Annotation Deleted"
    redirect_to(:action => :edit, :publication_id => @publication.id, :id => @identifier.id) and return
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

  # use to add annotations to an existing publication
  # we allow one oa_cite_identifier from a given collection per publication
  def edit_or_create
    # create the identifier if it doesn't exist
    find_publication
    collection_urn = params[:urn] || Cite::CiteLib.get_default_collection_urn()
    match_call = lambda do |p| return p.publication_id == @publication.id end
    existing_identifiers = OaCiteIdentifier.find_matching_identifiers(collection_urn,@current_user,match_call)
    if existing_identifiers.length == 1
      @identifier = existing_identifiers[0]
    elsif  existing_identifiers.length > 1
      flash[:error] = "Something went wrong - we have more than one oaciteidentifier #{existing_identifiers.to_s}"
      redirect_to dashboard_url and return
    end
    
    if @identifier.nil? || params[:commit] == 'Append'
      @identifier = OaCiteIdentifier.new_from_template(@publication,collection_urn,[])
      # append new
      target_uri = params[:target_uri]
      annotation_uri = @identifier.create_annotation(target_uri)
      # edit new
       redirect_to(:action => :edit,:annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
    else
      # otherwise give the user the choice
      # if it already existed, then it may have existing annotations for the requested target
      # look for any targets which reference the citation urn (regardless of source repo)
      # including any with subreference pointers in this target
      possible_matches = @identifier.matching_targets("#{Regexp.quote(params[:target_uri])}\#?",@creator_uri)
      if possible_matches.size > 0
        render(:template => 'cts_oac_identifiers/edit_or_create',
               :locals => {:matches => possible_matches})
      else     
        # append new
        # edit new
        target_uri = params[:target_uri]
        annotation_uri = @identifier.create_annotation(target_uri)
        # edit new
        redirect_to(:action => :edit,:annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
      end
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
    @html_preview =
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite oa_cite_preview.xsl})),
        { :e_convertResource => AgentHelper::agents_can_convert,
          :tool_url => Tools::Manager.link_to('oa_editor',:perseids,:edit,[@identifier])[:href],
          :e_createConverted => @identifier.publication.status == 'finalizing',
          :app_base => root_url,
        })
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
    creator = "#{Sosol::Application.config.site_user_namespace}#{URI.escape(@identifier.publication.creator.name)}"
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

  def destroy
    find_identifier 
    remaining = @identifier.publication.identifiers.select { |i| 
      i != @identifier 
    }
    if (remaining.size == 0)
      flash[:error] = "This would leave the publication without any identifiers."
      return redirect_to @identifier.publication
    end
    name = @identifier.title
    pub = @identifier.publication
    @identifier.destroy
    
    flash[:notice] = name + ' was successfully removed from your publication.'
    redirect_to pub
    return
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

