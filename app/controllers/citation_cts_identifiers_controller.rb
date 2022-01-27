class CitationCtsIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_action :authorize

  def edit
    redirect_to action: 'editxml', id: params[:id]
  end

  ## provide user with choice of editing or annotating a citation
  def confirm_edit_or_annotate
    find_publication
  end

  def edit_or_create
    find_publication

    if params[:urn].blank? || params[:collection].blank?
      flash[:error] = 'You must specify a URN and a Collection.'
      redirect_to dashboard_url
      return
    end

    versionIdentifier = params[:version_id].to_s
    sourceCollection = params[:collection].to_s
    sourceRepo = params[:src].to_s
    citationUrn = params[:urn].to_s

    @identifier = nil
    conflicts = []
    matches = []
    @publication.identifiers.each do |pubid|
      if pubid.is_a?(CitationCTSIdentifier)
        if pubid.urn_attribute == citationUrn
          matches << pubid
        elsif pubid.urn_attribute =~ /^#{Regexp.quote(citationUrn)}\./ ||
              citationUrn =~ /^#{Regexp.quote(pubid.urn_attribute)}\./
          # A conflicting citation is one which
          # a - is a parent of the required citation, or
          # b - is a child of the required citation
          conflicts << pubid
        end
      end
    end
    if conflicts.length.positive?
      conflicting_passage = Publication.find(conflicts.first.publication)
      flash[:error] =
        "You are already editing a parent or child of this citation. Please delete the <a href='#{url_for(@publication)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
      redirect_to dashboard_url
      return
    elsif matches.length == 1
      @identifier = matches[0]
    elsif matches.length.zero?
      pubtype ||= CTS::CTSLib.versionTypeForUrn(sourceCollection, citationUrn)
      #  we don't already have the identifier for this citation so create it
      @identifier = CitationCTSIdentifier.new_from_template(@publication, sourceCollection, citationUrn, pubtype)
    else
      flash[:error] =
        "One or more conflicting matches for this citation exist. Please delete the <a href='#{url_for(@publication)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
      redirect_to dashboard_url
      return
    end
    flash[:notice] = 'File retrieved.'
    expire_publication_cache
    redirect_to polymorphic_path([@publication, @identifier],
                                 action: :editxml) and return
  end

  def select
    find_publication
    startCite = params[:start_passage].strip
    endCite = params[:end_passage].strip
    if startCite == ''
      flash[:notice] = 'Supply a valid passage or passage range'
      render(template: 'citation_cts_identifiers/select',
             locals: { edition: params[:edition].to_s,
                       version_id: params[:version_id].to_s,
                       collection: params[:collection].to_s,
                       citeinfo: params[:citeinfo].to_s,
                       controller: params[:controller].to_s,
                       publication_id: params[:publication_id].to_s,
                       pubtype: params[:pubtype].to_s })
      nil
    else
      redirect_to(controller: 'cts_publications',
                  action: 'create_from_linked_urn',
                  collection: params[:collection].to_s,
                  urn: "#{params[:urn]}:#{params[:start_passage].strip}",
                  src: 'SoSOL')

    end
  end

  def create
    startCite = params[:start_passage].strip
    endCite = params[:end_passage].strip
    if startCite == ''
      flash[:notice] = 'Supply a valid passage or passage range'
      render(template: 'citation_cts_identifiers/create',
             locals: { edition: params[:edition].to_s,
                       collection: params[:collection].to_s,
                       citeinfo: params[:citeinfo].to_s,
                       controller: params[:controller].to_s,
                       publication_id: params[:publication_id].to_s,
                       pubtype: params[:pubtype].to_s })
      nil
    else
      # TODO: Ranges aren't implemented yet. To support citation ranges we
      # should treat each citation in the range as a separate identifier, by
      # first calling GetValidReff to get the list of valid citations in the
      # range, and then creating a citation identifier for each one.
      passage_urn = "#{params[:publication_urn]}:#{startCite}"
      publication_identifier = params[:publication_id].to_s
      @publication = Publication.find(params[:publication_id].to_s)
      conflicts = []
      @publication.identifiers.each do |pubid|
        next unless pubid.is_a?(CitationCTSIdentifier) &&
                    # A conflicting citation is one which
                    # a - has the exact same urn (i.e. the same citation), or
                    # b - is a parent of the required citation, or
                    # c - is a child of the required citation
                    (pubid.urn_attribute == passage_urn ||
                     pubid.urn_attribute =~ /^#{Regexp.quote(passage_urn)}\./ ||
                     passage_urn =~ /^#{Regexp.quote(pubid.urn_attribute)}\./)

        conflicts << pubid
      end

      if conflicts.length.positive?
        conflicting_passage = Publication.find(conflicts.first.publication)
        flash[:error] =
          "You are already editing this citation. Please delete the <a href='#{url_for(conflicting_passage)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
        redirect_to dashboard_url
        return
      end

      @identifier = CitationCTSIdentifier.new_from_template(@publication, params[:collection].to_s, passage_urn,
                                                            params[:pubtype].to_s)
      flash[:notice] = 'File created.'
      expire_publication_cache
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                   action: :editxml) and return
    end
  end

  def update
    find_identifier
    @original_commit_comment = ''
    # if user fills in comment box at top, it overrides the bottom
    params[:comment].to_s = params[:commenttop].to_s if !params[:commenttop].nil? && params[:commenttop].strip != ''
    begin
      commit_sha = @identifier.set_xml_content(params[:citation_cts_identifier].to_s,
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
                                   action: :editxml)
    rescue JRubyXML::ParseError => e
      flash.now[:error] =
        "#{e.to_str}.  This message is because the XML did not pass Relax NG validation.  This file was NOT SAVED. "
      render template: 'citation_cts_identifiers/edit'
    end
  end

  def preview
    find_identifier

    # Dir.chdir(File.join(Rails.root, 'data/xslt/'))
    # xslt = XML::XSLT.new()
    # xslt.xml = REXML::Document.new(@identifier.xml_content)
    # xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    # xslt.serve()

    @identifier_html_preview = @identifier.preview
  end

  protected

  def find_identifier
    @identifier = CitationCTSIdentifier.find(params[:id].to_s)
  end

  def find_publication_and_identifier
    @publication = Publication.find(params[:publication_id].to_s)
    find_identifier
  end

  def find_publication
    @publication = Publication.find(params[:publication_id].to_s)
  end
end
