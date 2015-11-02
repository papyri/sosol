class CtsOacIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:edit, :update, :append, :delete_annotation]
  
  def edit
    find_publication
    annotation_uri = params[:annotation_uri]
    if (annotation_uri)
      @creator_uri = @identifier.make_creator_uri()
      annotation = @identifier.get_annotation(annotation_uri)
      if (annotation.nil?)
        flash[:error] = "Annotation #{annotation_uri} not found"
        redirect_to(:action => :preview,:publication_id => @identifier.publication.id, :id => @identifier.id) and return
      elsif ((OacHelper::get_creator(annotation) != @creator_uri && ! (OacHelper::get_annotators(annotation).include? @creator_uri)) && @publication.status != 'finalizing')
        flash[:error] = "You can only edit annotations you created"
        redirect_to(:action => :preview,:publication_id => @identifier.publication.id, :id => @identifier.id) and return
      else
        editor_url = Tools::Manager.link_to('oa_editor',:perseids,:edit,[@identifier])[:href]
        editor_url = editor_url.sub(/URI/,annotation_uri)
        redirect_to(editor_url) and return
      end
    else
      params[:creator_uri] = @identifier.make_creator_uri()  
      params[:delete_link] = 
        url_for(:controller => 'cts_oac_identifiers', :action => 'delete_annotation', :publication_id => @identifier.publication.id, :id => @identifier.id, :annotation_uri => annotation_uri)
      params[:align_link] = 
        polymorphic_url([:link_alignment,@identifier.parentIdentifier.publication,@identifier.parentIdentifier],:a_id => @identifier.id.to_s, :annotation_uri => annotation_uri)        
      params[:form_token] = form_authenticity_token 
      params[:mode] = @identifier.mutable? ? 'edit' : 'preview'
      @identifier[:list] = @identifier.edit(parameters = params)
    end  
  end
  
  def edit_or_create
    # create the OAC identifier if it doesn't exist
    find_publication
    @parent = @publication.identifiers.select{ | pubid | pubid.name == params[:version_id] }.first
    @identifier = OACIdentifier.find_from_parent(@publication,@parent)
    
    if @identifier.nil? || params[:commit] == 'Append'
      @identifier = OACIdentifier.new_from_template(@publication,@parent)
      # append new
      target_uri = "#{root_url}cts/getpassage/#{@identifier.parentIdentifier.id}/#{params[:target_urn]}"
      annotation_uri = @identifier.create_annotation(target_uri)
      # edit new
       redirect_to(:action => :edit,:annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
    else
      # otherwise give the user the choice
      # if it already existed, then it may have existing annotations for the requested target
      # look for any targets which reference the citation urn (regardless of source repo)
      # including any with subreference pointers in this target
      possible_matches = @identifier.matching_targets("#{Regexp.quote(params[:target_urn])}\#?",@creator_uri)
      if possible_matches.size > 0
        render(:template => 'cts_oac_identifiers/edit_or_create',
               :locals => {:matches => possible_matches})
      else     
        # append new
        # edit new
        target_uri = "#{root_url}cts/getpassage/#{@identifier.parentIdentifier.id}/#{params[:target_urn]}"
        annotation_uri = @identifier.create_annotation(target_uri)
        # edit new
        redirect_to(:action => :edit,:annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
      end
    end    
  end

  # @deprecated 
  # replaced by use of the dmm_api append route
  def append
    find_publication_and_identifier
    # TODO validate input
    
    # accumulate target uris
    target_uris = []
    params[:valid_targets].split(',').each do |uri| 
      target_uris << params[uri] 
    end
    
    body_uri = params[:body_uri]
    title = params[:annotation_motivation]
    @creator_uri = @identifier.make_creator_uri()
    annotation_uri = @identifier.next_annotation_uri()
    @identifier.add_annotation(annotation_uri,target_uris,body_uri,title,@creator_uri,nil,'Added Annotation')
    redirect_to(:action => :preview,
       :annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  def update 
    find_publication_and_identifier
    annotation_uri = params[:annotation_uri]
    @creator_uri = @identifier.make_creator_uri()
    annotation = @identifier.get_annotation(annotation_uri)
    if (annotation.nil?)
      Rails.logger.error("Updating invalid annotation uri #{annotation_uri}")
      flash[:error] = "Annotation #{annotation_uri} not found"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    elsif (! @identifier.can_update?(annotation))
      Rails.logger.error("Updating unauthorized annotation uri #{annotation_uri}")
      flash[:error] = "You can only edit annotations you created"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    end
    target_uris = []
    params[:valid_targets].split(',').each do |uri| 
      target_uris << params[uri] 
    end
    body_uri = params[:body_uri]
    title = params[:annotation_motivation]
    @identifier.update_annotation(annotation_uri,target_uris,body_uri,title,@creator_uri,nil,"Updated Annotation #{annotation_uri}")
    redirect_to(:action => :preview,
       :annotation_uri => annotation_uri, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  def delete_annotation 
    find_publication_and_identifier
    annotation_uri = params[:annotation_uri]
    @creator_uri = @identifier.make_creator_uri()
    annotation = @identifier.get_annotation(annotation_uri)
    if (annotation.nil?)
      Rails.logger.error("Deleting invalid annotation uri #{annotation_uri}")
      flash[:error] = "Annotation #{annotation_uri} not found"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    elsif (! @identifier.can_update?(annotation,annotation))
      Rails.logger.error("Deleting unauthorized annotation uri #{annotation_uri}")
      flash[:error] = "You can only delete annotations you created"
      redirect_to(:action => :preview,:publication_id => @publication.id, :id => @identifier.id) and return
    end
    flash[:notice] = "Annotation Deleted"
    @identifier.delete_annotation(annotation_uri,"Deleted Annotation #{annotation_uri}")
    redirect_to(:action => :edit, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  def preview
    find_identifier
    if (@identifier.publication.status != 'finalizing')
      params[:creator_uri] = @identifier.make_creator_uri()       
    end
    @identifier[:html_preview] = @identifier.preview(params)
    @identifier[:annotation_uri] = params[:annotation_uri]
  end
  
  def annotate_xslt
    find_identifier
    render :xml => @identifier.parentIdentifier.passage_annotate_xslt
  end
  
    
  protected
    def find_identifier
      @identifier = OACIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end
    
  private
    def set_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Expose-Headers'] = 'ETag,x-json'
      headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
      headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match'
      headers['Access-Control-Max-Age'] = '86400'
  end
end
