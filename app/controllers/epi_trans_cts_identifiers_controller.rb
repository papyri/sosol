class EpiTransCtsIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml, :updatetext]
  before_filter :clear_cache, :only => [:update, :updatexml, :updatetext]

  # require 'xml'
  # require 'xml/xslt'

  def update_title
    find_identifier
    if @identifier.update_attributes(params[:epi_trans_cts_identifier]) && @identifier.update_title(params[:epi_trans_cts_identifier][:title])
      flash[:notice] = 'Title was successfully updated.'
    else 
      flash[:error] = 'Update to update title.'
    end
    return redirect_to polymorphic_url([@identifier.publication], :action => :show)
  end

  def edit_title
    find_identifier
  end
  
  def edit
    find_identifier
    override = agent_override('edit')
    if (override)
        flash.keep
        return redirect_to :action => override, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
    end
    # Add URL to image service for display of related images
    @identifier[:cite_image_service] = Tools::Manager.link_to('image_service',:cite,:context)[:href] 
    # find text for preview
    set_related_items
  end
  
  def editxml
    find_identifier
    @identifier[:cite_image_service] = Tools::Manager.link_to('image_service',:cite,:binary)[:href] 
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    render :template => 'epi_trans_cts_identifiers/editxml'
  end

  # Simple Edit Text action works on an ab inside of a translation element
  # supporting just plain text within that element for now
  def edittext
    find_identifier
    @is_editor_view = true
    set_related_items
    @identifier[:text_content] = @identifier.text_content
    render :template => 'epi_trans_cts_identifiers/edittext'
  end

  def updatetext
    find_identifier
    begin
      commit_sha = @identifier.update_text_content(params[:text_content],params[:comment])
      if params[:comment] != nil && params[:comment].strip != ""
        @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment].to_s, :reason => "commit" } )
        @comment.save
      end
      
      flash[:notice] = "File updated."
      expire_leiden_cache
      expire_publication_cache
      if %w{new editing}.include?@identifier.publication.status
        flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
      end
      unless (@identifier[:transform_messages].nil? )
        flash[:notice] = @identifier[:transform_messages].join('<br/>')
      end
    rescue JRubyXML::ParseError => parse_error
      flash.now[:error] = parse_error.to_str + ". This file was NOT SAVED."
    end
    flash.keep
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                               :action => :edittext) and return
  end 
  
  def create_from_selector
    publication = Publication.find(params[:publication_id].to_s)
    edition = params[:edition_urn]
    # if no edition, just use a fake one for use in path processing
    
    collection = params[:CTSIdentifierCollectionSelect]
    
    if (params[:commit] == "Create Translation")
      lang = params[:create_lang]
      # if the inventory doesn't have any edition for the translation then it's a new edition
      # whose urn will be in the CTSIdentifierEditionSelect param
      if (edition.nil?)
        edition = params[:CTSIdentifierEditionSelect]
      end
      @identifier =  EpiTransCTSIdentifier.new_from_template(publication,collection,edition,'translation',lang)
      @identifier.related_inventory.add_translation(params[:CTSIdentifierEditionSelect],@identifier)
    else
      translationName = collection + "/" + CTS::CTSLib.pathForUrn(edition,'translation')
      existing_identifiers = EpiTransCTSIdentifier.find_matching_identifiers(translationName,@current_user,nil)
      if (existing_identifiers && existing_identifiers.length > 0) 
        flash[:error] = "You are already editing that translation "
        flash[:error] += '<ul>'
        existing_identifiers.each do |conf_id|
          begin
            flash[:error] += "<li><a href='" + url_for(conf_id) + "'>" + conf_id.name.to_s + "</a></li>"
          rescue
            flash[:error] += "<li>" + conf_id.name.to_s + ":" + conf_id.publication.status + "</li>"
          end
        end
        render  "epi_trans_cts_identifiers/create",
          :locals => {
            :edition => params[:CTSIdentifierEditionSelect],
            :controller_name => 'epi_trans_cts_identifiers',
            :collection => collection,
            :publication_id => params[:publication_id], 
            :emend => :showemend}

        return
      end
      begin
        @identifier = EpiTransCTSIdentifier.new_from_inventory(publication,collection,edition,'translation')
      rescue Exception => e
        flash[:notice] = e.to_s
        redirect_to dashboard_url
        return
      end
    end
    flash[:notice] = "File created."
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit) and return
  end
  
  def link_citation
    find_identifier
    render(:template => 'citation_cts_identifiers/select',
           :locals => {:edition => @identifier.urn_attribute,
                       :version_id => @identifier.name,
                       :collection => @identifier.inventory,
                       :citeinfo => @identifier.related_inventory.parse_inventory(@identifier.urn_attribute),
                       :publication_id => @identifier.publication.id, 
                       :pubtype => 'translation'})
  end
  
  def update
    find_identifier
    @original_commit_comment = ''
    #if user fills in comment box at top, it overrides the bottom
    if params[:commenttop] != nil && params[:commenttop].strip != ""
      params[:comment] = params[:commenttop]
    end
    begin
      commit_sha = @identifier.set_xml_content(params[:tei_cts_identifier].to_s,
                                    params[:comment].to_s)
      if params[:comment] != nil && params[:comment].strip != ""
          @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment].to_s, :reason => "commit" } )
          @comment.save
      end
      flash[:notice] = "File updated."
      expire_publication_cache
      if %w{new editing}.include?@identifier.publication.status
          flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
      end
        
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                     :action => :edit)
      rescue JRubyXML::ParseError => parse_error
        flash.now[:error] = parse_error.to_str + 
          ".  This message is because the XML did not pass Relax NG validation.  This file was NOT SAVED. "
        render :template => 'epi_trans_cts_identifiers/edit'
      end #begin
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    find_identifier
    
    if @identifier.xml_content.to_s.empty?
      flash[:error] = "XML content is empty, unable to preview."
      redirect_to polymorphic_url([@identifier.publication, @identifier], :action => :editxml)
      return
    end
    set_related_items
    @identifier[:html_preview] = @identifier.preview
  end
  
  def destroy
    find_identifier 
    remaining = @identifier.publication.identifiers.select { |i| 
      i != @identifier && (i.class == EpiTransCTSIdentifier || i.class == EpiCTSIdentifier)
    }
    if (remaining.size == 0)
      flash[:error] = "This would leave the publication without any identifiers."
      return redirect_to @identifier.publication
    end
    name = @identifier.title
    pub = @identifier.publication
    @identifier.related_inventory.remove_translation(@identifier)
    @identifier.destroy
    
    flash[:notice] = name + ' was successfully removed from your publication.'
    redirect_to pub
    return
  end
  
  def annotate_xslt
    find_identifier
    render :xml => @identifier.passage_annotate_xslt
  end
  
  protected
    def find_identifier
      @identifier = EpiTransCTSIdentifier.find(params[:id].to_s)
    end

    def agent_override(method)
      agent = @identifier.agent 
      template = nil
      unless agent.nil?
        template = agent[:controllers][method]
      end
      return template
    end

    # it would be better to configure this on the cache store directly
    # but since we're using a file based store we clear it explicitly
    def clear_cache
      @identifier.clear_cache
    end

    def set_related_items
      @related_items = []
      @identifier.related_items.each do |r|
        if r =~ /^http/
          @related_items << { :url => r, :text => r }
        elsif r
         @related_items << { :url => polymorphic_url([@identifier.publication, r],:action => 'preview'), :text => 'Edition' }
      end
    end
      Rails.logger.info(">>>>>>>>>.RELATED=#{@related_items.inspect}")

    end
    
end
