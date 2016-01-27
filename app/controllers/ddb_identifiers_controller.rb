class DdbIdentifiersController < IdentifiersController
  #layout 'site'
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]
  
  # - GET /publications/1/ddb_identifiers/1/edit
  # - Edit DDB Text via Leiden+
  def edit
    find_identifier
    
    if @identifier.is_reprinted?
      reprint_identifier_string = [NumbersRDF::NAMESPACE_IDENTIFIER, @identifier.class::IDENTIFIER_NAMESPACE, @identifier.reprinted_in.to_s].join('/')
      reprint_identifier = @identifier.publication.identifiers.to_ary.find {|i| i.name == reprint_identifier_string}
      if !reprint_identifier.nil?
        reprint_identifier_path = polymorphic_path([@identifier.publication, reprint_identifier], :action => :edit)
        flash.now[:notice] = "This text is reprinted in <a href='#{reprint_identifier_path}'>#{reprint_identifier.title}</a>. Please <a href='#{reprint_identifier_path}'>edit the text there</a>, or <a href='#{polymorphic_path([@identifier.publication, @identifier], :action => :editxml)}'>edit this text's XML</a> to reflect the correct reprint relationship."
      else
        flash.now[:notice] = "This text is reprinted in #{reprint_identifier_string}, which is not associated with this publication (possibly a bug). Please edit the text there, or  <a href='#{polymorphic_path([@identifier.publication, @identifier], :action => :editxml)}'>edit this text's XML</a> to reflect the correct reprint relationship."
      end
    end
    
    begin
      # use a fragment cache for cases where we'd need to do a leiden transform
      if fragment_exist?(:action => 'edit', :part => "leiden_plus_#{@identifier.id}")
        @identifier[:leiden_plus] = read_fragment(:action => 'edit', :part => "leiden_plus_#{@identifier.id}")
      else
        if(Sosol::Application.config.respond_to?(:xsugar_standalone_enabled) && Sosol::Application.config.xsugar_standalone_enabled)
          original_xml = DDBIdentifier.preprocess(@identifier.xml_content)

          # strip xml:id from lb's
          original_xml = JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(original_xml),
            JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt ddb strip_lb_ids.xsl})))

          # get div type=edition from XML in string format for conversion
          abs = DDBIdentifier.get_div_edition(original_xml).join('')
          
          if @identifier.get_broken_leiden.nil?  
            @identifier[:leiden_plus] = abs
          else
            @identifier[:leiden_plus] = nil
            @bad_leiden = true
          end
          
        else
          @identifier[:leiden_plus] = @identifier.leiden_plus
        end
        write_fragment({:action => 'edit', :part => "leiden_plus_#{@identifier.id}"}, @identifier[:leiden_plus])
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
 
  # PUT /publications/1/ddb_identifiers/1/rename
  # Executes the actual rename of the 'SoSOL' temporary identifer to the correct final name - ex. BGU, O.Ber, etc
  # Overrides base Identifier rename controller to special-case DDB collections
  def rename
    find_identifier
    collection_name = params[:new_name].split('/').last.split(';').first
    if CollectionIdentifier.new.has_collection?(collection_name)
      begin
        @identifier.rename(params[:new_name].to_s, :update_header => true, :set_dummy_header => params[:set_dummy_header])
        flash[:notice] = "Identifier renamed."
      rescue RuntimeError => e
        flash[:error] = e.to_s
      end
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :rename_review) and return
    else
      flash[:notice] = "Collection does not exist. Identifier NOT renamed. Create collection first."
      redirect_to :controller => 'collection_identifiers', :action => 'update_review', :short_name => collection_name, :entry_identifier_id => @identifier.id
    end
  end
  
  # - PUT /publications/1/ddb_identifiers/1/update
  # - Update DDB Text via Leiden+
  def update
    find_identifier
    @bad_leiden = false
    @original_commit_comment = ''
    #if user fills in comment box at top, it overrides the bottom
    if params[:commenttop] != nil && params[:commenttop].strip != ""
      params[:comment] = params[:commenttop]
    end
    if params[:commit] == "Save With Broken Leiden+" #Save With Broken Leiden+ button is clicked
      @identifier.save_broken_leiden_plus_to_xml(params[:ddb_identifier_leiden_plus].to_s, params[:comment].to_s)
      @bad_leiden = true
      flash.now[:notice] = "File updated with broken Leiden+ - XML and Preview will be incorrect until fixed"
      expire_leiden_cache
      expire_publication_cache
        @identifier[:leiden_plus] = params[:ddb_identifier_leiden_plus].to_s
        @is_editor_view = true
        render :template => 'ddb_identifiers/edit'
    else #Save button is clicked
      begin
        commit_sha = @identifier.set_leiden_plus(params[:ddb_identifier_leiden_plus].to_s,
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
                                     :action => :edit)
      rescue RXSugar::NonXMLParseError => parse_error
        flash.now[:error] = "Error parsing Leiden+ at line #{parse_error.line}, column #{parse_error.column}.  This file was NOT SAVED. "
        new_content = insert_error_here(parse_error.content, parse_error.line, parse_error.column)
        @identifier[:leiden_plus] = new_content
        @bad_leiden = true
        @original_commit_comment = params[:comment]
        @is_editor_view = true
        render :template => 'ddb_identifiers/edit'
      rescue JRubyXML::ParseError => parse_error
        flash.now[:error] = parse_error.to_str + 
          ".  This message is because the XML created from Leiden+ below did not pass Relax NG validation.  This file was NOT SAVED. "
        @bad_leiden = true #to keep from trying to parse the L+ as XML when render edit template
        @identifier[:leiden_plus] = params[:ddb_identifier_leiden_plus]
        @is_editor_view = true
        render :template => 'ddb_identifiers/edit'
      end #begin
    end #when
  end
  
  # Pull DDB Text XML file from repository and creates a page set via XSLT up to add, modify, or delete
  # Front Matter or Line by Line commentary
  # - *Params*  :
  #   - +none+
  # - *Returns* :
  #   - @identifier[:html_preview] - data for view to display
  #   - @is_editor_view - tell view to display edit menu at top of page
  def commentary
    find_identifier

    begin
      @identifier[:html_preview] = 
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          DDBIdentifier.preprocess(@identifier.xml_content)),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt ddb commentary.xsl})),
          {})
    rescue JRubyXML::ParseError => parse_error
      flash.now[:error] = parse_error.to_str + 
          ".  This message is because the XML is unable to be transformed by the line-by-line commentary XSLT."
      @identifier[:html_preview] = ''
    end
      
    @is_editor_view = true
  end
  
  # Updates a DDB Text with Line by Line commentary
  # - *Params*  :
  #   - +line_id+ -> id attribute value of the 'li' tag this commentary is associated with
  #   - +reference+ -> defaults to numeric portion of 'line_id' - but user changable to reference multiple lines, etc. 
  #   - +content+ -> contains the commentary 'Leiden' to convert to XML that will be added to the DDB Text XML
  #   - +original_item_id+ -> XSLT consistently calculated id to reference this 'text' line with
  # - *Returns* :
  #   - to commentary view
  # - *Rescue*  :
  #   - JRubyXML::ParseError -  if XML does not validate against tei-epidoc.rng file and returns to commentary view with flash error
  def update_commentary
    find_identifier
    
    begin

      @identifier.update_commentary(params[:line_id].to_s, params[:reference].to_s, params[:content].to_s, params[:original_item_id].to_s)
      flash[:notice] = "File updated with new commentary."

      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :commentary)

    rescue JRubyXML::ParseError => parse_error
      flash[:error] = parse_error.to_str + 
          ".  This message is because the XML created from Line By Line Leiden below did not pass Relax NG validation.  This file was NOT SAVED. "
     
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :commentary)
    end
  end
  
  # Updates a DDB Text with Front Matter commentary
  # - *Params*  :
  #   - +content+ -> contains the commentary 'Leiden' to convert to XML that will be added to the DDB Text XML
  # - *Returns* :
  #   - to commentary view
  # - *Rescue*  :
  #   - JRubyXML::ParseError -  if XML does not validate against tei-epidoc.rng file and returns to commentary view with flash error
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
  
  # Deletes Front Matter commentary from a DDB Text
  # - *Params*  :
  #   - +none+
  # - *Returns* :
  #   - to commentary view
  def delete_frontmatter_commentary
    find_identifier
    
    @identifier.update_frontmatter_commentary('',true)
    
    flash[:notice] = "Front matter commentary entry removed."
    
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :commentary)
  end
  
  # Deletes Line by Line commentary from a DDB Text
  # - *Params*  :
  #   - +line_id+ -> id attribute value of the 'li' tag this commentary is associated with
  #   - +reference+ -> defaults to numeric portion of 'line_id' - but user changable to reference multiple lines, etc. 
  #   - +content+ -> contains the commentary 'Leiden' to convert to XML that will be added to the DDB Text XML
  #   - +original_item_id+ -> XSLT consistently calculated id to reference this 'text' line with
  # - *Returns* :
  #   - to commentary view
  def delete_commentary
    find_identifier
    
    @identifier.update_commentary(params[:line_id].to_s, params[:reference].to_s, params[:content].to_s, params[:original_item_id].to_s, true)
    
    flash[:notice] = "Commentary entry removed."
    
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :commentary)
  end
  
  # - GET /publications/1/ddb_identifiers/1/preview
  # - Provides preview of what the DDB Text XML from the repository will look like with PN Stylesheets applied
  def preview
    find_identifier

    @identifier[:html_preview] = @identifier.preview
    
    @is_editor_view = true
  end
  
  protected
  
    # Sets the identifier instance variable values
    # - *Params*  :
    #   - +id+ -> id from identifier table of the DDB Text
    def find_identifier
      @identifier = DDBIdentifier.find(params[:id].to_s)
    end
  
    # Sets the publication instance variable values and then calls find_identifier
    # - *Params*  :
    #   - +publication_id+ -> id from publication table of the publication containing this DDB Text
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
end
