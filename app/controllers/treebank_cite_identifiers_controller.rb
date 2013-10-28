# Controller for Treebank Cite Identifiers
class TreebankCiteIdentifiersController < IdentifiersController 
  
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]


  # responds to a request to create a new file
  # @param
  def create
    
  end
  
  def edit
    find_identifier
    @identifier[:list] = @identifier.edit(parameters = params)
  end
  
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview(parameters = params)
  end
    
  
  protected
    def find_identifier
      @identifier = TreebankCiteIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end  
end