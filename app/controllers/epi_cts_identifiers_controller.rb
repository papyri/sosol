class EpiCtsIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  
  # GET /publications/1/epi_cts_identifiers/1/edit
  def edit
    find_identifier
    redirect_to :action =>"editxml",:publication=>params[:publication],:id=>params[:id]
  end
  
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    @identifier[:facs] = @identifier.facs
    render :template => 'epi_cts_identifiers/editxml'
  end
  
  def create_from_selector
    publication = Publication.find(params[:publication_id].to_s)
    edition = params[:edition_urn]
    collection = params[:CTSIdentifierCollectionSelect]
    
    @identifier = EpiCTSIdentifier.new_from_template(publication,collection,edition,'edition',nil)
    
    flash[:notice] = "File created."
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit) and return
  end
  
   def link_translation
    find_identifier
    render(:template => 'epi_trans_cts_identifiers/create',:locals => {:edition => @identifier.urn_attribute,:collection => @identifier.inventory,:controller => 'epi_trans_cts_identifiers',:publication_id => @identifier.publication.id, :emend => :showemend})
   end

  
  # PUT /publications/1/epi_cts_identifiers/1/update
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
        render :template => 'epi_cts_identifiers/edit'
      end #begin
  end
  
  def commentary
    find_identifier

    @identifier_html_preview = 
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

    @identifier_html_preview = @identifier.preview
  end
  
  protected
    def find_identifier
      @identifier = EpiCTSIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
end
