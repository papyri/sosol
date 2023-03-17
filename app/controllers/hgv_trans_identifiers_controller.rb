class HGVTransIdentifiersController < IdentifiersController
  # layout 'site'
  before_action :authorize
  # require 'xml'
  # require 'xml/xslt'

  # Edit Translation
  def edit
    find_identifier

    # get leiden
    begin
      @identifier.non_database_attribute[:leiden_trans] = @identifier.leiden_trans
      if @identifier.non_database_attribute[:leiden_trans].nil?
        flash.now[:error] = 'File loaded from broken Leiden'
        @identifier.non_database_attribute[:leiden_trans] = @identifier.get_broken_leiden
      end
    rescue RXSugar::XMLParseError => e
      flash.now[:error] = "Error parsing XML at line #{e.line}, column #{e.column}"
      new_content = insert_error_here(e.content, e.line, e.column)
      @identifier.non_database_attribute[:leiden_trans] = new_content
    end

    # find text for preview
    @identifier.non_database_attribute[:text_html_preview] = @identifier.related_text.preview

    @is_editor_view = true
  end

  # Add new 'div' type="translation" with new language attribute
  # - *Params*  :
  #   - +lang+ -> the new language to add (used in 'xml:lang' attribute)
  # - *Returns* :
  #   - to Edit Translation view
  def add_new_lang_to_xml
    # raise "Function needs protection to prevent wipe out of existing data. Nothing happened."

    find_identifier
    # must prevent existing lang from being wiped out
    if @identifier.translation_already_in_language?(params[:lang])
      flash[:warning] = 'Language is already present in translation.'
      redirect_to polymorphic_path([@identifier.publication, @identifier], action: :edit)
      return
    end
    @identifier.stub_text_structure(params[:lang])
    @identifier.save
    redirect_to polymorphic_path([@identifier.publication, @identifier], action: :edit)
  end

  # Update Translation
  def update
    find_identifier
    @bad_leiden = false
    @original_commit_comment = ''
    # if user fills in comment box at top, it overrides the bottom
    params[:comment] = params[:commenttop] if !params[:commenttop].nil? && params[:commenttop].strip != ''
    if params[:commit] == 'Save With Broken Leiden+'
      # broken leiden
      @identifier.save_broken_leiden_trans_to_xml(params[:hgv_trans_identifier][:leiden_trans], params[:comment].to_s)
      @bad_leiden = true
      flash.now[:notice] = 'File updated with broken Leiden+ - XML and Preview will be incorrect until fixed'
      expire_publication_cache
      @identifier.non_database_attribute[:leiden_trans] = params[:hgv_trans_identifier][:leiden_trans].to_s

      @is_editor_view = true

      # find text for preview
      @identifier.non_database_attribute[:text_html_preview] = @identifier.related_text.preview

      render template: 'hgv_trans_identifiers/edit'

    else # normal save
      # checking for parse error
      begin
        commit_sha = @identifier.set_leiden_translation_content(params[:hgv_trans_identifier][:leiden_trans].to_s,
                                                                params[:comment].to_s)

        if !params[:comment].nil? && params[:comment].strip != ''
          @comment = Comment.new({ git_hash: commit_sha, user_id: @current_user.id,
                                   identifier_id: @identifier.origin.id, publication_id: @identifier.publication.origin.id, comment: params[:comment].to_s, reason: 'commit' })
          @comment.save
        end

        flash[:notice] = 'File updated.'
        expire_publication_cache
        if %w[new editing].include? @identifier.publication.status
          flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
        end

        redirect_to polymorphic_path([@identifier.publication, @identifier], action: :edit)

      # non parsing
      rescue RXSugar::NonXMLParseError => e
        flash.now[:error] =
          "Error parsing Leiden+ at line #{e.line}, column #{e.column}.  This file was NOT SAVED."
        new_content = insert_error_here(e.content, e.line, e.column)
        @identifier.non_database_attribute[:leiden_trans] = new_content
        @bad_leiden = true
        @original_commit_comment = params[:comment]
        @is_editor_view = true

        # find text for preview
        @identifier.non_database_attribute[:text_html_preview] = @identifier.related_text.preview

        render template: 'hgv_trans_identifiers/edit'

      # invalid xml
      rescue JRubyXML::ParseError => e
        flash.now[:error] =
          "#{e.to_str}.  This message is because the XML created from Leiden+ below did not pass Relax NG validation.  This file was NOT SAVED.  "
        @identifier.non_database_attribute[:leiden_trans] = params[:hgv_trans_identifier][:leiden_trans]
        # @identifier.non_database_attribute[:leiden_plus] = parse_error.message

        @is_editor_view = true

        # find text for preview
        @identifier.non_database_attribute[:text_html_preview] = @identifier.related_text.preview

        render template: 'hgv_trans_identifiers/edit'
      end
    end
  end

  # - GET /publications/1/ddb_identifiers/1/preview
  # - Provides preview of what the Translation XML from the repository will look like with PN Stylesheets applied
  def preview
    find_identifier

    if @identifier.xml_content.to_s.empty?
      flash[:error] = 'XML content is empty, unable to preview.'
      redirect_to polymorphic_url([@identifier.publication, @identifier], action: :editxml)
      return
    end
    @is_editor_view = true
    @identifier_html_preview = @identifier.preview
  end

  protected

  # Sets the identifier instance variable values
  # - *Params*  :
  #   - +id+ -> id from identifier table of the Translation
  def find_identifier
    @identifier = HGVTransIdentifier.find(params[:id].to_s)
  end
end
