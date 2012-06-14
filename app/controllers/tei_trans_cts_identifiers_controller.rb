class TeiTransCtsIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  # require 'xml'
  # require 'xml/xslt'
  
  
  def edit
    find_identifier
    redirect_to :action =>"editxml",:publication=>params[:publication],:id=>params[:id]
  end
    

  def add_new_lang_to_xml
  # raise "Function needs protection to prevent wipe out of existing data. Nothing happened."
   
  	find_identifier
  	#must prevent existing lang from being wiped out
    if @identifier.translation_already_in_language?(params[:lang])
      flash[:warning] = "Language is already present in translation."
      redirect_to polymorphic_path([@identifier.publication, @identifier], :action => :edit)
      return
    end
    @identifier.stub_text_structure(params[:lang])
    @identifier.save
    redirect_to polymorphic_path([@identifier.publication, @identifier], :action => :edit)
  end  


  
  def update
    find_identifier
    @original_commit_comment = ''
    #if user fills in comment box at top, it overrides the bottom
    if params[:commenttop] != nil && params[:commenttop].strip != ""
      params[:comment] = params[:commenttop]
    end
    begin
      commit_sha = @identifier.set_xml_content(params[:tei_cts_identifier],
                                    params[:comment])
      if params[:comment] != nil && params[:comment].strip != ""
          @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
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
        render :template => 'tei_trans_cts_identifiers/edit'
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
    
    @identifier[:html_preview] = @identifier.preview
  end
  
  
  protected
    def find_identifier
      @identifier = TeiTransCTSIdentifier.find(params[:id])
    end
end
