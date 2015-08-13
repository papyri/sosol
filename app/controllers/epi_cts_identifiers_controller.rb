class EpiCtsIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]
  before_filter :clear_cache, :only => [:update, :updatexml]

  # GET /publications/1/epi_cts_identifiers/1/edit
  # - Edit Text redirects to EditXML
  def edit
    find_identifier
    redirect_to :action =>"editxml",:publication=>params[:publication],:id=>params[:id]
  end
    
  # GET /publications/1/epi_cts_identifiers/1/edit
  # - Edit Text via Leiden+
  def leiden
    find_identifier
    
    begin
      # use a fragment cache for cases where we'd need to do a leiden transform
      if fragment_exist?(:action => 'leiden', :part => "leiden_plus_#{@identifier.id}")
        @identifier[:leiden_plus] = read_fragment(:action => 'leiden', :part => "leiden_plus_#{@identifier.id}")
      else
        if(defined?(XSUGAR_STANDALONE_ENABLED) && XSUGAR_STANDALONE_ENABLED)
          original_xml = EpiCTSIdentifier.preprocess(@identifier.xml_content)

          # strip xml:id from lb's
          original_xml = JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(original_xml),
            JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt ddb strip_lb_ids.xsl})))

          # get div type=edition from XML in string format for conversion
          abs = EpiCTSIdentifier.get_div_edition(original_xml).to_s
          
          if @identifier.get_broken_leiden.nil?  
            @identifier[:leiden_plus] = abs
          else
            @identifier[:leiden_plus] = nil
            @bad_leiden = true
          end
          
        else
          @identifier[:leiden_plus] = @identifier.leiden_plus
        end
        write_fragment({:action => 'leiden', :part => "leiden_plus_#{@identifier.id}"}, @identifier[:leiden_plus])
      end
      if @identifier[:leiden_plus].nil?
        flash.now[:error] = "File loaded from broken Leiden+"
        @identifier[:leiden_plus] = @identifier.get_broken_leiden
      end
    rescue RXSugar::XMLParseError => parse_error
      flash.now[:error] = "Error parsing XML at line #{parse_error.line}, column #{parse_error.column}"
      new_content = insert_error_here(parse_error.content, parse_error.line, parse_error.column)
      @identifier[:leiden_plus] = new_content
    end
    @is_editor_view = true
  end
  
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @identifier[:cite_image_service] = Tools::Manager.link_to('image_service',:cite,:binary)[:href] 
    @is_editor_view = true
    render :template => 'epi_cts_identifiers/editxml'
  end
  
  def create_from_selector
    publication = Publication.find(params[:publication_id].to_s)
    edition = params[:edition_urn]
    collection = params[:CTSIdentifierCollectionSelect]
    
    @identifier = EpiCTSIdentifier.new_from_template(publication,collection,edition,'edition',nil)
    @identifier.related_inventory.add_edition(@identifier)

    flash[:notice] = "File created."
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit) and return
  end
  
  def link_translation
    find_identifier
    render  "epi_trans_cts_identifiers/create",
     :action => "create",
     :locals => {
     :edition => @identifier.urn_attribute,
     :collection => @identifier.inventory,
     :publication_id => @identifier.publication.id, 
     :controller_name => 'epi_trans_cts_identifiers',
     :emend => :showemend } and return
  end
   
  def link_citation
    find_identifier
    render(:template => 'citation_cts_identifiers/select',
           :locals => {:edition => @identifier.urn_attribute,
                       :version_id => @identifier.name,
                       :collection => @identifier.inventory,
                       :citeinfo => @identifier.related_inventory.parse_inventory(),
                       :publication_id => @identifier.publication.id, 
                       :pubtype => 'edition'})
  end
  
  def link_alignment
    find_publication_and_identifier

    # TODO eventually should be able to link from places other 
    # than an annotation?
    if (params[:annotation_uri])
      redirect_to(:controller => 'alignment_cite_identifiers', 
        :publication_id => @publication.id,
        :a_id => params[:a_id],
        :annotation_uri => params[:annotation_uri],
        :action => :create_from_annotation) and return
    else 
      flash.now[:error] = "Missing input details for annotation."
      redirect_to dashboard_url
    end
    
  end
  
  # - PUT /publications/1/epi_cts_identifiers/1/update
  # - Update Text via Leiden+
  def update
    find_identifier
    @bad_leiden = false
    @original_commit_comment = ''
    #if user fills in comment box at top, it overrides the bottom
    if params[:commenttop] != nil && params[:commenttop].strip != ""
      params[:comment] = params[:commenttop]
    end
    if params[:commit] == "Save With Broken Leiden+" #Save With Broken Leiden+ button is clicked
      @identifier.save_broken_leiden_plus_to_xml(params[:epi_cts_identifier_leiden_plus].to_s, params[:comment].to_s)
      @bad_leiden = true
      flash.now[:notice] = "File updated with broken Leiden+ - XML and Preview will be incorrect until fixed"
      expire_leiden_cache
      expire_publication_cache
        @identifier[:leiden_plus] = params[:epi_cts_identifier_leiden_plus].to_s
        @is_editor_view = true
        render :template => 'epi_cts_identifiers/leiden'
    else #Save button is clicked
      begin
        commit_sha = @identifier.set_leiden_plus(params[:epi_cts_identifier_leiden_plus].to_s,
                                    params[:comment].to_s)
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
        
        redirect_to polymorphic_path([@identifier.publication, @identifier],
                                     :action => :leiden)
      rescue RXSugar::NonXMLParseError => parse_error
        flash.now[:error] = "Error parsing Leiden+ at line #{parse_error.line}, column #{parse_error.column}.  This file was NOT SAVED. "
        new_content = insert_error_here(parse_error.content, parse_error.line, parse_error.column)
        @identifier[:leiden_plus] = new_content
        @bad_leiden = true
        @original_commit_comment = params[:comment]
        @is_editor_view = true
        render :template => 'epi_cts_identifiers/leiden'
      rescue JRubyXML::ParseError => parse_error
        flash.now[:error] = parse_error.to_str + 
          ".  This message is because the XML created from Leiden+ below did not pass Relax NG validation.  This file was NOT SAVED. "
        @bad_leiden = true #to keep from trying to parse the L+ as XML when render edit template
        @identifier[:leiden_plus] = params[:epi_cts_identifier_leiden_plus]
        @is_editor_view = true
        render :template => 'epi_cts_identifiers/leiden'
      end #begin
    end #when
  end
  
  
  def commentary
    find_identifier

    @identifier[:html_preview] = 
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(
        EpiCTSIdentifier.preprocess(@identifier.xml_content)),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt perseus commentary.xsl})),
        {})
      
  end
  
  def update_commentary
    find_identifier
    
    begin

      @identifier.update_commentary(params[:line_id].to_s, params[:reference].to_s, params[:content].to_s, params[:original_item_id].to_s)
      flash[:notice] = "File updated with new commentary."

      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :commentary)

    rescue JRubyXML::ParseError => parse_error
      flash[:error] = parse_error.to_str + 
          ".  This message is because the XML created from Front Matter Leiden below did not pass Relax NG validation.  This file was NOT SAVED. "
     
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :commentary)
    end
  end
  
  def update_frontmatter_commentary
    find_identifier
    
    begin

      @identifier.update_frontmatter_commentary(params[:content].to_s)

      flash[:notice] = "File updated with new commentary."

      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :commentary)
    rescue JRubyXML::ParseError => parse_error
      flash[:error] = parse_error.to_str + 
          ".  This message is because the XML created from Front Matter Leiden below did not pass Relax NG validation.  This file was NOT SAVED. "
      
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :commentary)
    end
  end
  
  def delete_frontmatter_commentary
    find_identifier
    
    @identifier.update_frontmatter_commentary('',true)
    
    flash[:notice] = "Front matter commentary entry removed."
    
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :commentary)
  end
  
  def delete_commentary
    find_identifier
    
    @identifier.update_commentary(params[:line_id].to_s, params[:reference].to_s, params[:content].to_s, params[:original_item_id].to_s, true)
    
    flash[:notice] = "Commentary entry removed."
    
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :commentary)
  end
  
  # GET /publications/1/epi_cts_identifiers/1/preview
  def preview
    find_identifier
    
    # Dir.chdir(File.join(Rails.root, 'data/xslt/'))
    # xslt = XML::XSLT.new()
    # xslt.xml = REXML::Document.new(@identifier.xml_content)
    # xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    # xslt.serve()
    @identifier[:cite_image_service] = Tools::Manager.link_to('image_service',:cite,:context)[:href] 
    @identifier[:html_preview] = @identifier.preview
  end
  
  def annotate_xslt
    find_identifier
    render :xml => @identifier.passage_annotate_xslt
  end
  
  protected
    def find_identifier
      @identifier = EpiCTSIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end

    # it would be better to configure this on the cache store directly
    # but since we're using a file based store we clear it explicitly
    def clear_cache
      @identifier.clear_cache
    end
end
