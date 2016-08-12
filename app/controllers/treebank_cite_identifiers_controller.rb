# Controller for Treebank Cite Identifiers
class TreebankCiteIdentifiersController < IdentifiersController 
  
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update, :updatexml]
  before_filter :clear_cache, :only => [:update, :updatexml]

  # Creation of Treebank Cite Identifiers is done only
  # via the api

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

  def edit
    find_identifier
    @can_compare = true
    tool = @identifier.get_editor_agent()
    tool_link = Tools::Manager.link_to('treebank_editor',tool,:edit,[@identifier])
    parameters = {}
    parameters[:s] = params[:s] || 1
    parameters[:title] = @identifier.title
    parameters[:doc_id] = @identifier.id.to_s
    parameters[:max] = 50 # TODO - make max sentences configurable
    parameters[:target] = tool_link[:target]
    parameters[:tool_url] = tool_link[:href]
    @list = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite treebanklist.xsl})),
        parameters)
  end


   def editxml
    find_identifier
    @is_editor_view = true
    render :template => 'treebank_cite_identifiers/editxml'
  end
  
  # preview
  # outputs the sentence list
  def preview
    find_identifier
    @can_compare = true
    tool = @identifier.get_editor_agent()
    tool_link = Tools::Manager.link_to('treebank_editor',tool,:view,[@identifier])
    parameters = {}
    parameters[:s] = params[:s] || 1
    parameters[:title] = @identifier.title
    parameters[:doc_id] = @identifier.id.to_s
    parameters[:max] = 50 # TODO - make max sentences configurable
    parameters[:target] = tool_link[:target]
    parameters[:tool_url] = tool_link[:href]
    @list = JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(@identifier.content),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt cite treebanklist.xsl})),
          parameters)
 end

  # Identify a set of treebank files which are comparable to the actionable identifier
  # and present the user with a list of links to the review service tool
  # If the current user is NOT the owner of the actionable identifier, the current users files
  # are searched for comparable files and the current users file is considered as the "gold standard" in the review
  # with the actionable identifier being the one which is reviewed. (This is the use case where a reviewer starts from
  # a file submitted to a board or sent to them as a link and wants to compare it against their own equivalent file)
  # If the current user is the owner and the current user is a board member, then the boards the current
  # user belongs to are searched for comparable files and the actionable file is considered as the "gold standard"
  # in the review. (This is the use case where a user starts from their own gold standard in their own account
  # and compares it to the equivalent files in the boards they are a member of, to find submissions they need to review)
  # - *Params* :
  #   - +id+ -> Identifier of the actionable treebank file
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
          this_set = compare.clone
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

  # Displays the sentences of the treebank file linked to
  # the treebank_reviewer tool.
  #
  # The transformation of the treebank data
  # to the sentence list expects there to be a comment in the treebank
  # file specifying the identifier of another treebank file in the
  # system which is to be used as the gold standard, e.g.
  # <comment class="gold">ID</comment> (as a child of the parent <treebank/> element)
  # - *Params* :
  #   - +id+ -> Identifier of the treebank file
  #   - +s+ -> id of the starting sentence (Optional, default is 1)
  def review
    find_identifier
    tool = @identifier.get_editor_agent()
    tool_link = Tools::Manager.link_to('treebank_reviewer',tool,:review,[@identifier])
    parameters = {}
    parameters[:s] = params[:s] || 1
    parameters[:title] = @identifier.title
    parameters[:doc_id] = @identifier.id.to_s
    parameters[:max] = 50 # TODO - make max sentences configurable
    parameters[:target] = tool_link[:target]
    parameters[:tool_url] = tool_link[:href]
    @list = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite treebanklist.xsl})),
        parameters)
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
