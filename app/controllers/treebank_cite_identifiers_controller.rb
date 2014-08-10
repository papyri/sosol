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
    @identifier[:compare] = compare_link
  end
  
   def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @identifier[:compare] = compare_link
    @is_editor_view = true
    render :template => 'treebank_cite_identifiers/editxml'
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

  def compare_link
    if @identifier.publication.origin.owner_id != @current_user.id
      compare = Tools::Manager.link_to('review_service',@identifier.class.to_s,:review,[@identifier])
      if (compare) 
        matching_files =
          @identifier.matching_files(["owner_id = #{@current_user.id}"])
      end
    elsif @current_user.boards 
      compare = Tools::Manager.link_to('review_service',@identifier.class.to_s,:gold,[@identifier])
      if (compare) 
        matching_files = 
          @identifier.matching_files({:owner_type => 'Board', :status => 'voting', :owner_id => @current_user.boards.collect { |b| b.id }})
      end
    end
    if (compare && matching_files && matching_files.length > 0)
      matching_files.each do |f|
        compare[:href] += "&#{compare[:replace_param]}=#{f.id.to_s}"
      end
      compare
    end
  end
end
