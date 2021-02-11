class ApisIdentifiersController < IdentifiersController
  before_action :authorize
  before_action :ownership_guard, :only => [:update, :updatexml]
  require 'pp'

  def editold
    find_identifier
    @identifier.get_epidoc_attributes
    @is_editor_view = true
  end

  def edit
    find_identifier
    @is_editor_view = true
  end

  def update
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
    rescue JRubyXML::ParseError => parse_error
      flash[:error] = parse_error.to_str + ". This file was NOT SAVED."
    end      
    redirect_to :action => :edit, :id => @identifier.id
  end

  def preview
    find_identifier
    @is_editor_view = true
  end

  def generate_flash_message
    flash[:notice] = "File updated."
    if %w{new editing}.include? @identifier.publication.status
      flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
    end      
  end

  def save_comment (comment, commit_sha)
    if comment != nil && comment.strip != ""
      @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.id, :publication_id => @identifier.publication_id, :comment => comment, :reason => "commit" } )
      @comment.save
    end
  end

  def find_identifier
    @identifier = APISIdentifier.find(params[:id].to_s)
  end

  def xml
    find_identifier
    send_data(@identifier.xml_content, :filename => @identifier.title, :type => "application/xml")
  end
end
