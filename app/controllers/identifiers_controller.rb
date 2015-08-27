# Superclass of the ddb (Text), hgv_Meta, and hgv_trans controllers
# - contains methods common to these identifiers
class IdentifiersController < ApplicationController
  # - GET /publications/1/xxx_identifiers/1/editxml
  # - edit the XML file from the repository of the associated identifier
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    render :template => 'identifiers/editxml'
  end
  
  # GET /publications/1/xxx_identifiers/1/history
  # - retrieve the history of commits from the repository for the associated identifier and creates a list
  #   of them with URL's to click to git a 'diff' view of each commit
  def history
    find_identifier
    @is_editor_view = true
    @commits = @identifier.get_commits(20).map{|c| @identifier.commit_id_to_hash(c)}
    render :template => 'identifiers/history'
  end
  
  # POST /identifiers
  def create
    @publication = Publication.find(params[:publication_id].to_s)
    identifier_type = params[:identifier_type].constantize
    if params[:apis_collection]
      @identifier = APISIdentifier.new_from_template(@publication, params[:apis_collection].to_s)
    else
      @identifier = identifier_type.new_from_template(@publication)
    end
    if @identifier.nil?
      flash[:error] = "Publication already has identifiers of this type, cannot create new file from templates."
      redirect_to polymorphic_path([@publication],
                                   :action => :show) and return
    else
      flash[:notice] = "File created."
      expire_publication_cache
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   :action => :edit) and return
    end
  end
  
  # GET /publications/1/xxx_identifiers/1/rename_review
  # Used as entry point to rename a 'SoSOL' temporary identifer to the correct final name - ex. BGU, O.Ber, etc
  def rename_review
    #TODO - does this need to be locked down somehow so not get to it via URL entry?
    find_identifier
    @is_editor_view = true
    render :template => 'identifiers/rename_review'
  end
  
  # PUT /publications/1/xxx_identifiers/1/rename
  # Executes the actual rename of the 'SoSOL' temporary identifer to the correct final name - ex. BGU, O.Ber, etc
  def rename
    find_identifier
    begin
      @identifier.rename(params[:new_name], :update_header => true, :set_dummy_header => params[:set_dummy_header])
      flash[:notice] = "Identifier renamed."
    rescue RuntimeError => e
      flash[:error] = e.to_s
    end
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :rename_review) and return
  end
  
  # - PUT /publications/1/xxx_identifiers/1/updatexml
  # - updates the XML file in the repository of the associated identifier
  def updatexml
    find_identifier
    # strip carriage returns
    xml_content = params[@identifier.class.to_s.underscore][:xml_content].gsub(/\r\n?/, "\n")
    #if user fills in comment box at top, it overrides the bottom
    if params[:commenttop] != nil && params[:commenttop].strip != ""
      params[:comment] = params[:commenttop]
    end
    begin
      commit_sha = @identifier.set_xml_content(xml_content,
                                  :comment => params[:comment])
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
                                 :action => :editxml) and return
    rescue JRubyXML::ParseError => parse_error
      flash.now[:error] = parse_error.to_str + ". This file was NOT SAVED."
      new_content = insert_error_here(xml_content, parse_error.line, parse_error.column)
      @identifier[:xml_content] = new_content
      @is_editor_view = true
      render :template => 'identifiers/editxml'
    end
  end
  
  # - PUT /publications/1/xxx_identifiers/1/show_commit/40 char commit id
  # - Show the diff view of a specific get repository commit
  def show_commit
    find_identifier
    identifier_commits = @identifier.get_commits(20)
    commit_index = identifier_commits.find_index {|c| c == params[:commit_id].to_s}
    @commit = @identifier.commit_id_to_hash(identifier_commits[commit_index])
    @prev_commit = commit_index > 0 ? identifier_commits[commit_index-1] : nil
    @next_commit = commit_index < (identifier_commits.length - 1) ? identifier_commits[commit_index+1] : nil
    
    @diff = `git --git-dir="#{@identifier.owner.repository.path}" diff --unified=5000 #{params[:commit_id]}^ #{params[:commit_id]} -- "#{@identifier.to_path}"`
    if @diff.blank?
      # empty diff, probably pre-rename; go ahead and show the whole diff
      # TODO: actually track down renames? If an identifier is modified by
      # a repo-wide commit and then renamed, this will currently load the
      # entire (giant) commit. But most of our renames will be from new
      # texts coming in with no prior history.
      @diff = `git --git-dir="#{@identifier.owner.repository.path}" diff --unified=5000 #{params[:commit_id]}^ #{params[:commit_id]}`
    end
    Rails.logger.info(@commit.inspect)
    @is_editor_view = true
    render :template => 'identifiers/show_commit'
  end

  protected
  
    def expire_publication_cache
      expire_fragment(:controller => 'user', :action => 'dashboard', :part => "your_publications_#{@current_user.id}")
    end
  
    def expire_leiden_cache
      expire_fragment(:action => 'edit', :part => "leiden_plus_#{@identifier.id}")
    end
    
    def ownership_guard
      find_identifier
      if !@identifier.publication.mutable_by?(@current_user)
        flash[:error] = 'Operation not permitted.'
        redirect_to dashboard_url
      end
    end
  
    # Used to insert '**POSSIBLE ERROR**' in Leiden+ and XML edit page when there is a parse or validation error
    # - this same logic found in DDBIdentifiers view's commentary.haml and edit.haml - javascript section
    def insert_error_here(content, line, column)
      # this routine is to place the error message below in the Leiden+ or XML returned when a parse error
      # occurs by taking the line and column from the message and giving the user the place in the content
      # the parse error occured in xsugars processing - may or may not be where the real error is depending
      # on what the error is - this processing is by character because there are multiple byte characters
      # possible in the text and a way to place msg with taking that into account
      #
      # line starts at 1 because first character is on first line before incrementing in loop
      # same logic for column, already on first character before incrementing in loop 
      # 'col' check has to come before 'new line' check in case error is on last char in the line
      line_cnt = 1
      col_cnt = 1
      content_error_here = ''
      add_error = false
      
      content.each_char do |i|
        if line_cnt == line
          if col_cnt == column
            content_error_here << "**POSSIBLE ERROR**"
            add_error = true
          end
          # if on the line with error but at the end without putting in the message, then put the message in
          if (i == "\n" && add_error == false)
              content_error_here << "**POSSIBLE ERROR**"
              add_error = true
          end
          col_cnt += 1
        end
        if i == "\n"
          line_cnt += 1
        end
        content_error_here << i
      end
      return content_error_here
    end

end
