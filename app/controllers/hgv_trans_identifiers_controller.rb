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
    rescue RXSugar::XMLParseError => parse_error
      flash.now[:error] = "Error parsing XML at line #{parse_error.line}, column #{parse_error.column}"
      @identifier[:leiden_trans] = parse_error.content
    end
    
    
    #find text for preview
    @identifier.publication.identifiers.each do |id|
      if (id.class.to_s == "DDBIdentifier")
        @identifier[:text_html_preview] = id.preview
      end    
    end
            
  end
  
  def update
    #raise "contents are: " + params[:content]
    find_identifier
    commit_sha = @identifier.set_leiden_translation_content(params[:hgv_trans_identifier][:leiden_trans], params[:comment])
    
    if params[:comment] != nil && params[:comment].strip != ""
      @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
      @comment.save    
    end
    
    flash[:notice] = "File updated."
    if %w{new editing}.include?@identifier.publication.status
      flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
    end
    
    #@identifier.set_epidoc(params[:hgv_trans_identifier], params[:comment])
    #redirect_to dashboard_url
    redirect_to polymorphic_path([@identifier.publication, @identifier], :action => :edit)
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
