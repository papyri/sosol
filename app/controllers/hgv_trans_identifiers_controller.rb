class HgvTransIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  # require 'xml'
  # require 'xml/xslt'
  
  def edit
    find_identifier
    
    #get leiden
    begin
      @identifier[:leiden_trans] = @identifier.leiden_trans
      if @identifier[:leiden_trans].nil?
        flash.now[:error] = "File loaded from broken Leiden"
        @identifier[:leiden_trans] = @identifier.get_broken_leiden
      end
    rescue RXSugar::XMLParseError => parse_error
      flash.now[:error] = "Error parsing XML at line #{parse_error.line}, column #{parse_error.column}"
      @identifier[:leiden_trans] = parse_error.content
    end
    
    #find text for preview
    @identifier[:text_html_preview] = @identifier.related_text.preview
    
  end
  
  def update
    find_identifier
    @bad_leiden = false
    @original_commit_comment = ''
    if params[:commit]== "Save With Broken Leiden+"
     #broken leiden
      @identifier.save_broken_leiden_trans_to_xml(params[:hgv_trans_identifier][:leiden_trans], params[:comment])
      @bad_leiden = true
      flash.now[:notice] = "File updated with broken Leiden+ - XML and Preview will be incorrect until fixed"
        @identifier[:leiden_trans] = params[:hgv_trans_identifier][:leiden_trans]
        render :template => 'hgv_trans_identifiers/edit'
    
    else #normal save
      begin#checking for parse error
        
        
        commit_sha = @identifier.set_leiden_translation_content(params[:hgv_trans_identifier][:leiden_trans], params[:comment])
        
        if params[:comment] != nil && params[:comment].strip != ""
          @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
          @comment.save    
        end
        
        flash[:notice] = "File updated."
        if %w{new editing}.include?@identifier.publication.status
          flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
        end

        redirect_to polymorphic_path([@identifier.publication, @identifier], :action => :edit)
        
      #non parsing  
      rescue RXSugar::NonXMLParseError => parse_error
        flash.now[:error] = "Error parsing Leiden+ at line #{parse_error.line}, column #{parse_error.column}"
        @identifier[:leiden_trans] = parse_error.content
        @bad_leiden = true
        @original_commit_comment = params[:comment]
        render :template => 'hgv_trans_identifiers/edit'
      
      #invalid xml
      rescue JRubyXML::ParseError => parse_error
        flash[:error] = parse_error.to_str + 
                        ".  This message because the XML created from Leiden+ below did not pass Relax NG validation.  "
        @identifier[:leiden_trans] = params[:hgv_trans_identifier][:leiden_trans]
        #@identifier[:leiden_plus] = parse_error.message
        render :template => 'hgv_trans_identifiers/edit'
        
      end#checking for parse error
    end
    
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    find_identifier
    
    if @identifier.xml_content.to_s.empty?
      flash[:error] = "XML content is empty, unable to preview."
      redirect_to polymorphic_url([@identifier.publication, @identifier], :action => :editxml)
      return
    end
    
    @identifier[:html_preview] = @identifier.preview
  end
  
  
  protected
    def find_identifier
      @identifier = HGVTransIdentifier.find(params[:id])
    end
end
