class IdentifiersController < ApplicationController
  # def method_missing(method_name, *args)
  #   identifier = Identifier.find(params[:id])
  #   redirect_to :controller => identifier.class.to_s.pluralize.underscore, :action => method_name
  # end
  
  # GET /publications/1/xxx_identifiers/1/editxml
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    render :template => 'identifiers/editxml'
  end
  
  # GET /publications/1/xxx_identifiers/1/history
  def history
    find_identifier
    @identifier.get_commits
    @identifier[:commits].each do |commit|
      if commit[:message].empty?
        commit[:message] = '(no commit message)'
      end
      commit[:url] = GITWEB_BASE_URL +
                     ["#{@identifier.publication.owner.repository.path.sub(/^#{REPOSITORY_ROOT}/,'db/git')}",
                      "a=commitdiff",
                      "h=#{commit[:id]}"].join(';')
    end
    render :template => 'identifiers/history'
  end
  
  # POST /identifiers
  def create
    @publication = Publication.find(params[:publication_id])
    identifier_type = params[:identifier_type].constantize
    
    @identifier = identifier_type.new_from_template(@publication)
    flash[:notice] = "File created."
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit) and return
  end
  
  def rename_review
    find_identifier
    render :template => 'identifiers/rename_review'
  end
  
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
  
  # PUT /publications/1/xxx_identifiers/1/updatexml
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
        @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
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
      render :template => 'identifiers/editxml'
    end
  end
  
  protected
  
  def expire_publication_cache
    expire_fragment(:controller => 'user', :action => 'dashboard', :part => "your_publications_#{@current_user.id}")
  end
  
  def expire_leiden_cache
    expire_fragment(:action => 'edit', :part => "leiden_plus_#{@identifier.id}")
  end
  
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
    content.each_char do |i|
      if line_cnt == line
        if col_cnt == column
          content_error_here << "**POSSIBLE ERROR**"
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
