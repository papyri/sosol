class SyriacaIdentifiersController < IdentifiersController
  #layout 'site'
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]
  

  def edit
    find_identifier
    redirect_to polymorphic_path([@identifier.publication, @identifier], :action => :editxml)
  end 

  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    render :template => 'syriaca_identifiers/editxml'
  end
  

  # - GET /publications/1/syriaca_identifiers/1/preview
  # - Provides preview of what the XML from the repository will look like with stylesheets applied
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview
    @is_editor_view = true
  end
  
  protected
  
    # Sets the identifier instance variable values
    # - *Params*  :
    #   - +id+ -> id from identifier table
    def find_identifier
      @identifier = SyriacaIdentifier.find(params[:id].to_s)
    end
  
    # Sets the publication instance variable values and then calls find_identifier
    # - *Params*  :
    #   - +publication_id+ -> id from publication table of the publication containing this item 
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
end
