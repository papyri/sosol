class TEICTSIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_action :authorize

  ## TODO
  # we to offer the following options:
  # 1. select a citation or citations to edit -> results in creation of one or more CitationCTSIdentifier obj
  # 2. download/export full XML of outermost tei:text element [ maybe limited to a specific role? ]
  # 3. upload/import full XML of outermost tei:text element [ maybe limited to a specific role? ]
  # 3. edit/update commentary (teiHeader)
  # 4. select a translation to edit ?
  # 5. add a CITE index
  # 6. update a CITE index

  # Ideally CitationCTSIdentifier Interface would offer options to create stand-off markup in the form of
  # CITE index entries, for example:
  #    from within a select a range of XML to create an index entry from
  #    e.g. this range is a quotation, this range is a named entity, this range maps to image coordinates X

  # so related identifier types would be:
  ## TEICitationCTSIdentifier
  ## TEITransCTSIdentifier
  ## CITEIndexIdentifier

  def edit
    find_identifier
    # Redirecting to Publication because don't want to immediately show them
    # the full XML - instead from Publication they can select a citation, etc.
    publication = @identifier.publication.id
    redirect_to polymorphic_path([@identifier.publication],
                                 action: :show)
  end

  def exportxml
    find_identifier
  end

  def create_from_selector
    publication = Publication.find(params[:publication_id].to_s)
    edition = params[:edition_urn]
    collection = params[:CTSIdentifierCollectionSelect]

    @identifier = TEICTSIdentifier.new_from_template(publication, collection, edition, 'edition', nil)

    flash[:notice] = 'File created.'
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 action: :edit) and return
  end

  def link_translation
    find_identifier
    render(template: 'tei_trans_cts_identifiers/create',
           locals: { edition: @identifier.urn_attribute, collection: @identifier.inventory,
                     controller: 'tei_trans_cts_identifiers', publication_id: @identifier.publication.id, emend: :showemend })
  end

  def link_citation
    find_identifier
    render(template: 'citation_cts_identifiers/select',
           locals: { edition: @identifier.urn_attribute,
                     version_id: @identifier.name,
                     collection: @identifier.inventory,
                     citeinfo: @identifier.related_inventory.parse_inventory,
                     controller: 'citation_cts_identifiers',
                     publication_id: @identifier.publication.id,
                     pubtype: 'edition' })
  end

  def update
    find_identifier
    @original_commit_comment = ''
    # if user fills in comment box at top, it overrides the bottom
    params[:comment] = params[:commenttop] if !params[:commenttop].nil? && params[:commenttop].strip != ''
    begin
      commit_sha = @identifier.set_xml_content(params[:tei_cts_identifier].to_s,
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

      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   action: :edit)
    rescue JRubyXML::ParseError => e
      flash.now[:error] =
        "#{e.to_str}.  This message is because the XML did not pass Relax NG validation.  This file was NOT SAVED. "
      render template: 'tei_cts_identifiers/edit'
    end
  end

  def preview
    find_identifier

    # Dir.chdir(File.join(Rails.root, 'data/xslt/'))
    # xslt = XML::XSLT.new()
    # xslt.xml = REXML::Document.ncew(@identifier.xml_content)
    # xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    # xslt.serve()

    @identifier_html_preview = @identifier.preview
  end

  protected

  def find_identifier
    @identifier = TEICTSIdentifier.find(params[:id].to_s)
  end

  def find_publication_and_identifier
    @publication = Publication.find(params[:publication_id].to_s)
    find_identifier
  end
end
