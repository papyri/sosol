# Controller for Treebank Cite Identifiers
class AlignmentCiteIdentifiersController < IdentifiersController 
  
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]


  def update_title
    find_identifier
    # TODO if we start keeping the title in the contents of the file
    # then we need to update the xml too but for now this is only a field
    # on the model in the mysql db
    if @identifier.update_attributes(params[:alignment_cite_identifier])
      flash[:notice] = 'Title was successfully updated.'
    else
      flash[:error] = 'Unable to update title'
    end
    redirect_to :action =>"edit",:id=>params[:id]
  end

  def edit_title
    find_identifier
  end

  def edit
    find_identifier
    parameters = {}
    parameters[:s] = params[:s] || 1
    parameters[:title] = @identifier.title
    parameters[:doc_id] = @identifier.id.to_s
    parameters[:max] = 50 # TODO - make max sentences configurable
    parameters[:tool_url] = Tools::Manager.link_to('alignment_editor',:alpheios,:edit,[@identifier])[:href]
    @list = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite alignment_list.xsl})),
        parameters)
  end
  
   def editxml
    find_identifier
    @is_editor_view = true
    render :template => 'alignment_cite_identifiers/editxml'
  end
  
  def preview
    find_identifier
    parameters = {}
    parameters[:s] = params[:s] || 1
    parameters[:title] = @identifier.title
    parameters[:doc_id] = @identifier.id.to_s
    parameters[:max] = 50 # TODO - make max sentences configurable
    parameters[:tool_url] = Tools::Manager.link_to('alignment_editor',:alpheios,:view,[@identifier])[:href]
    @list = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite alignment_list.xsl})),
        parameters)
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
      @identifier = AlignmentCiteIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end  
end
