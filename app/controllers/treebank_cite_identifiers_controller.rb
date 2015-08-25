# Controller for Treebank Cite Identifiers
class TreebankCiteIdentifiersController < IdentifiersController 
  
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]
  before_filter :clear_cache, :only => [:update, :updatexml]

  def update_title
    find_identifier
    # TODO if we start keeping the title in the contents of the file
    # then we need to update the xml too but for now this is only a field
    # on the model in the mysql db
    if @identifier.update_attributes(params[:treebank_cite_identifier])
      flash[:notice] = 'Title was successfully updated.'
    else 
      flash[:error] = 'Update to update title.'
    end
    redirect_to :action =>"edit",:id=>params[:id]
  end

  def edit_title
    find_identifier
  end

  # responds to a request to create a new file
  # @param
  def create
    
  end
  
  def edit
    find_identifier
    @identifier[:list] = @identifier.edit(parameters = params)
    @can_compare = true
  end

  def review
    find_identifier
    @identifier[:list] = @identifier.review(parameters = params)
  end
  
   def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    render :template => 'treebank_cite_identifiers/editxml'
  end
  
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview(parameters = params)
    @can_compare = true
  end

  def compare
    find_identifier
    # this is too inefficient -- can't require a retrieval and parsing
    # of all treebank files in all possible relevant branches in order
    # to provide this functionality. We need to either have a property
    # in the mysql db on the identifier that allows us to make this 
    # determination efficiently or we need to hand it off to an external
    # service to manage for us

    matching_files = {}
    if @identifier.publication.origin.owner_id != @current_user.id
      compare = Tools::Manager.link_to('review_service',@identifier.class.to_s,:review,[@identifier])
      if (compare) 
        matching_files['my'] =
          @identifier.matching_files(["owner_id = #{@current_user.id}"])
      end
    elsif @current_user.boards 
      compare = Tools::Manager.link_to('review_service',@identifier.class.to_s,:gold,[@identifier])
      if (compare) 
        @current_user.boards.each do |b|
          matching_files[b.friendly_name] = 
            @identifier.matching_files(
              {:owner_type => 'Board', :status => 'voting', :owner_id => b.id })
        end
      end
    end
    @compare_list = []
    if (compare && matching_files.keys.length > 0)
      matching_files.keys.each do |s|
        if matching_files[s].length > 0
          this_set = compare
          this_set[:title] = "#{s} files"
          matching_files[s].each do |f|
            this_set[:href] += "&#{this_set[:replace_param]}=#{f.id.to_s}"
            this_set[:text] += " #{f.name} "
          end
          @compare_list << this_set
        end
      end
    end
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

    # it would be better to configure this on the cache store directly
    # but since we're using a file based store we clear it explicitly
    def clear_cache
      @identifier.clear_cache
    end

end
