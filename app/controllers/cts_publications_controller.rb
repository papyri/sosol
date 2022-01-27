class CtsPublicationsController < PublicationsController
  layout Sosol::Application.config.site_layout
  before_action :authorize
  before_action :ownership_guard,
                only: %i[confirm_archive archive confirm_withdraw withdraw confirm_delete destroy submit]

  ## Create/Update a CTS Publication from a linked URN
  def create_from_linked_urn
    if params[:urn].blank? || params[:collection].blank?
      flash[:error] = 'You must specify a URN and a Collection.'
      redirect_to dashboard_url
      return
    end

    urnObj = CTS::CTSLib.urnObj(params[:urn].to_s)
    sourceRepo = params[:src]
    sourceCollection = params[:collection]

    # get the Parent version URN and publication type
    versionUrn = urnObj.getUrnWithoutPassage

    # if the version Urn is the same as the supplied urn then we don't have a citation specified
    citationUrn = versionUrn == params[:urn] ? nil : params[:urn]

    pubtype = CTS::CTSLib.versionTypeForUrn(sourceCollection, versionUrn)
    if pubtype.nil?
      flash[:error] = "No publication found for #{params[:urn]} in #{sourceCollection} inventory."
      redirect_to dashboard_url
      return
    end

    versionIdentifier = "#{sourceCollection}/#{CTS::CTSLib.pathForUrn(versionUrn, pubtype)}"

    # check to see if the user is already working on the parent publication
    @publication = nil
    existing_identifiers = []
    possible_conflicts = Identifier.where(name: versionIdentifier).includes(:publication)
    actual_conflicts = possible_conflicts.select do |pc|
      (pc.publication && (pc.publication.owner == @current_user) && !%w[archived
                                                                        finalized].include?(pc.publication.status))
    end
    existing_identifiers += actual_conflicts

    if existing_identifiers.length.positive?
      conflicting_publication = existing_identifiers.first.publication
      conflicting_publications = existing_identifiers.collect(&:publication).uniq

      if conflicting_publications.length > 1
        flash[:error] = 'Error creating publication: multiple conflicting publications'
        flash[:error] += '<ul>'
        conflicting_publications.each do |conf_pub|
          flash[:error] += "<li><a href='#{url_for(conf_pub)}'>#{conf_pub.title}</a></li>"
        end
        flash[:error] += '</ul>'
        redirect_to dashboard_url
        return
      end

      if conflicting_publication.status == 'committed'
        expire_publication_cache
        conflicting_publication.archive
      else
        @publication = conflicting_publication
      end
    end

    if @publication.nil?
      # User doesn't have the parent publication yet so create it
      identifiers_hash = {}
      [versionIdentifier, OACIdentifier.make_name(versionIdentifier)].each do |id|
        key = CTS::CTSLib.getIdentifierKey(id)
        identifiers_hash[key] = []
        identifiers_hash[key] << id
      end
      @publication = Publication.new
      @publication.owner = @current_user
      @publication.creator = @current_user

      # HACK: for IDigGreek to enable link in to create annotations on an edition that doesn't
      # exist in the master repo
      temp_id = nil
      identifier_class = nil
      Sosol::Application.config.site_identifiers.split(',').each do |identifier_name|
        ns = identifier_name.constantize::IDENTIFIER_NAMESPACE
        next unless CTS::CTSLib.getIdentifierKey(versionIdentifier) == ns

        identifier_class = Object.const_get(identifier_name)
        temp_id = identifier_class.new(name: versionIdentifier)
      end

      if @publication.repository.get_file_from_branch(temp_id.to_path, 'master').blank?
        fullurn = "urn:cts:#{versionUrn}"
        # fetch a title without creating from template
        @publication.title = identifier_class.new(name: identifier_class.next_temporary_identifier(sourceCollection,
                                                                                                   fullurn, 'edition', 'ed')).name
        @publication.status = 'new'
        @publication.save!

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
        new_cts = identifier_class.new_from_template(@publication, sourceCollection, fullurn, 'edition', 'ed')

        # create the inventory metadata records
        # we can't do this until the publication has already been branched from the master
        # because it doesn't exist in the master git repo
        # and is only carried along with the publication until it is finalized
        begin
          # first the inventory record
          CTSInventoryIdentifier.new_from_template(@publication, sourceCollection, versionIdentifier, versionUrn)
        rescue StandardError => e
          @publication.destroy
          flash[:notice] = "Error creating publication (during creation of inventory excerpt):#{e}"
          redirect_to dashboard_url
          return
        end

      else
        @publication.populate_identifiers_from_identifiers(
          identifiers_hash, CTS::CTSLib.versionTitleForUrn(sourceCollection, "urn:cts:#{versionUrn}")
        )

        if @publication.save!
          @publication.branch_from_master

          # create the temporary CTS citation and inventory metadata records
          # we can't do this until the publication has already been branched from the master
          # because they don't exist in the master git repo
          # and are only carried along with the publication until it is finalized
          begin
            # first the inventory record
            CTSInventoryIdentifier.new_from_template(@publication, sourceCollection, versionIdentifier, versionUrn)
          rescue StandardError => e
            @publication.destroy
            flash[:notice] = "Error creating publication (during creation of inventory excerpt):#{e}"
            redirect_to dashboard_url
            return
          end

          # need to remove repeat against publication model
          e = Event.new
          e.category = 'started editing'
          e.target = @publication
          e.owner = @current_user
          e.save!
        end
      end
    end
    redirect_to(controller: 'citation_cts_identifiers',
                action: 'confirm_edit_or_annotate',
                publication_id: @publication.id,
                version_id: versionIdentifier,
                collection: sourceCollection,
                urn: citationUrn,
                src: sourceRepo)
  end

  ###
  # Creates a new CTS identifier from the CTS selector element
  ###
  def create_from_selector
    edition = params[:edition_urn]
    if edition.nil?
      # if no edition, just use a fake one for use in path processing
      edition = "urn:cts:#{params[:work_urn]}.tempedition"
    end
    collection = params[:CTSIdentifierCollectionSelect]
    identifier = "#{collection}/#{CTS::CTSLib.pathForUrn(edition, 'edition')}"
    identifier_class = Object.const_get(CTS::CTSLib.getIdentifierClassName(identifier))

    if params[:commit] == 'Create Edition'
      lang = params[:lang]
      # TODO: figure out language for new editions from inventory
      lang ||= 'ed'
      new_publication = Publication.new(owner: @current_user, creator: @current_user)
      urn = "urn:cts:#{edition}"
      # fetch a title without creating from template
      new_publication.title = identifier_class.new(name: identifier_class.next_temporary_identifier(collection, urn,
                                                                                                    'edition', lang)).name
      Rails.logger.info("Creating new title #{new_publication.title}")
      new_publication.status = 'new'
      new_publication.save!

      # branch from master so we aren't just creating an empty branch
      new_publication.branch_from_master

      # create the new template
      new_cts = identifier_class.new_from_template(new_publication, collection, urn, 'edition', lang)
      @publication = new_publication

      # create the temporary CTS citation and inventory metadata records
      # we can't do this until the publication has already been branched from the master
      # because they don't exist in the master git repo
      # and are only carried along with the publication until it is finalized
      begin
        # first the inventory record
        CTSInventoryIdentifier.new_from_template(@publication, collection, identifier, edition)
        # now the citation identifier
        if params[:citation_urn]
          # TODO: this needs to support direction creation from a translation as well as an edition?
          citation_identifier = CitationCTSIdentifier.new_from_template(@publication, collection,
                                                                        params[:citation_urn].to_s, 'edition')
        end
      rescue StandardError => e
        @publication.destroy
        flash[:notice] = "Error creating publication (during creation of inventory excerpt):#{e}"
        redirect_to dashboard_url
        return
      end

      flash[:notice] = 'Publication was successfully created.'
      expire_publication_cache
      redirect_to @publication

    # proceed to create from existing identifier file -- only if we have an identifier
    elsif params[:edition_urn]
      related_identifiers = [identifier]
      conflicting_identifiers = []

      # loop through related identifiers looking for conflicts
      related_identifiers.each do |relid|
        possible_conflicts = Identifier.where(name: relid).includes(:publication)
        actual_conflicts = possible_conflicts.select do |pc|
          (pc.publication && (pc.publication.owner == @current_user) && !%w[archived
                                                                            finalized].include?(pc.publication.status))
        end
        conflicting_identifiers += actual_conflicts
      end

      if conflicting_identifiers.length.positive?
        Rails.logger.info("Conflicting identifiers: #{conflicting_identifiers.inspect}")
        conflicting_publication = conflicting_identifiers.first.publication
        conflicting_publications = conflicting_identifiers.collect(&:publication).uniq

        if conflicting_publications.length > 1
          flash[:error] = 'Error creating publication: multiple conflicting publications'
          flash[:error] += '<ul>'
          conflicting_publications.each do |conf_pub|
            flash[:error] += "<li><a href='#{url_for(conf_pub)}'>#{conf_pub.title}</a></li>"
          end
          flash[:error] += '</ul>'
          redirect_to dashboard_url
          return
        end

        if conflicting_publication.status == 'committed'
          expire_publication_cache
          conflicting_publication.archive
        else
          flash[:error] =
            "Error creating publication: publication already exists. Please delete the <a href='#{url_for(conflicting_publication)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
          redirect_to dashboard_url
          return
        end
      end
      # else
      identifiers_hash = {}

      related_identifiers.each do |relid|
        key = CTS::CTSLib.getIdentifierKey(relid)
        identifiers_hash[key] = [] unless identifiers_hash.key?(key)
        identifiers_hash[key] << relid
      end

      @publication = Publication.new
      @publication.owner = @current_user
      @publication.creator = @current_user
      @publication.populate_identifiers_from_identifiers(
        identifiers_hash, CTS::CTSLib.versionTitleForUrn(collection, params[:edition_urn].to_s)
      )

      if @publication.save!
        @publication.branch_from_master

        # create the temporary CTS citation and inventory metadata records
        # we can't do this until the publication has already been branched from the master
        # because they don't exist in the master git repo
        # and are only carried along with the publication until it is finalized
        begin
          # first the inventory record
          CTSInventoryIdentifier.new_from_template(@publication, collection, identifier, edition)
          # now the citation identifier
          if params[:citation_urn]
            # TODO: this needs to support direction creation from a translation as well as an edition?
            citation_identifier = CitationCTSIdentifier.new_from_template(@publication, collection,
                                                                          params[:citation_urn].to_s, 'edition')
          end
        rescue StandardError => e
          @publication.destroy
          flash[:notice] = "Error creating publication (during creation of inventory excerpt):#{e}"
          redirect_to dashboard_url
          return
        end

        # need to remove repeat against publication model
        e = Event.new
        e.category = 'started editing'
        e.target = @publication
        e.owner = @current_user
        e.save!

        flash[:notice] = 'Publication was successfully created.'
        expire_publication_cache
        # redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
        redirect_to @publication
      else
        flash[:notice] = 'Error creating publication'
        redirect_to dashboard_url
      end
    else
      flash[:notice] = 'You must specify an edition.'
      redirect_to dashboard_url
    end
  end
end
