class PublicationsController < ApplicationController
  # #layout 'site'
  before_action :authorize
  before_action :ownership_guard,
                only: %i[confirm_archive archive confirm_withdraw withdraw confirm_delete destroy submit]

  def new; end

  def download
    require 'zip'
    require 'zip/filesystem'
    require 'pp'

    @publication = Publication.find(params[:id].to_s)

    file_friendly_name = @publication.title.gsub(%r{[\\/:."*?<>|\s]+}, '-')
    # raise file_friendly_name
    t = Tempfile.new("publication_download_#{file_friendly_name}-#{request.remote_ip}")

    Zip::OutputStream.open(t.path) do |zos|
      @publication.identifiers.each do |id|
        # raise id.title + " ... " + id.name + " ... " + id.title.gsub(/\s/,'_')

        # simple paths for just this pub
        zos.put_next_entry("#{id.class::FRIENDLY_NAME}-#{id.title.gsub(/\s/, '_')}.xml")

        # full path as used in repo
        # zos.put_next_entry( id.to_path)

        zos << id.xml_content
      end
    end

    # End of the block  automatically closes the zip? file.

    # The temp file will be deleted some time...

    filename = "#{@publication.creator.name}_#{file_friendly_name}_#{Time.zone.now.strftime('%a%d%b%Y_%H%M')}"
    filename = "#{filename.gsub(%r{[\\/:."*?<>|\s]+}, '-')}.zip"
    # raise filename
    send_data File.read(t.path), type: 'application/zip', filename: filename

    t.close
    t.unlink
  end

  def advanced_create
    @publication = Publication.new
  end

  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new
    @publication.owner = @current_user
    @publication.populate_identifiers_from_identifiers(
      params[:pn_id].to_s
    )

    @publication.creator = @current_user
    # @publication.creator_type = "User"
    # @publication.creator_id = @current_user

    if @publication.save
      @publication.branch_from_master

      # need to remove repeat against publication model
      e = Event.new
      e.category = 'started editing'
      e.target = @publication
      e.owner = @current_user
      e.save!

      flash[:notice] = 'Publication was successfully created.'
      expire_publication_cache
      redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    else
      flash[:notice] = 'Error creating publication'
      redirect_to dashboard_url
    end
  end

  def create_from_identifier
    if params[:id].blank?
      flash[:error] = 'You must specify an identifier.'
      redirect_to dashboard_url
      return
    end

    identifier = params[:id]
    related_identifiers = nil

    related_identifiers = if %r{papyri\.info/dclp}.match?(identifier)
                            [identifier]
                          else # cromulent dclp hack to circumvent number server
                            NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier)
                          end

    publication_from_identifier(identifier, related_identifiers)
  end

  def create_from_biblio_template
    new_publication = Publication.new(owner: @current_user, creator: @current_user)

    # fetch a title without creating from template
    new_publication.title = BiblioIdentifier.new(name: BiblioIdentifier.next_temporary_identifier).titleize

    new_publication.status = 'new'
    new_publication.save!

    # branch from master so we aren't just creating an empty branch
    new_publication.branch_from_master

    # create the required meta data and transcriptions
    new_biblio = BiblioIdentifier.new_from_template(new_publication)
    @publication = new_publication

    flash[:notice] = 'Publication was successfully created.'
    expire_publication_cache
    redirect_to @publication
  end

  def create_from_apis_template
    new_publication = Publication.new(owner: @current_user, creator: @current_user)
    new_publication.title = APISIdentifier.new(name: APISIdentifier.next_temporary_identifier(params[:apis_collection].to_s)).titleize
    new_publication.status = 'new'
    new_publication.save!

    # branch from master so we aren't just creating an empty branch
    new_publication.branch_from_master

    new_apis = APISIdentifier.new_from_template(new_publication, params[:apis_collection].to_s)
    @publication = new_publication

    flash[:notice] = 'Publication was successfully created.'
    expire_publication_cache
    redirect_to @publication
  end

  def create_from_dclp_template
    @publication = Publication.new_from_dclp_template(@current_user)

    # create event
    e = Event.new
    e.category = 'created'
    e.target = @publication
    e.owner = @current_user
    e.save!

    flash[:notice] = 'Publication was successfully created.'
    # redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    expire_publication_cache
    redirect_to @publication
  end

  def create_from_templates
    @publication = Publication.new_from_templates(@current_user)

    # create event
    e = Event.new
    e.category = 'created'
    e.target = @publication
    e.owner = @current_user
    e.save!

    flash[:notice] = 'Publication was successfully created.'
    # redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    expire_publication_cache
    redirect_to @publication
  end

  # list is in the form of pn id's separated by returns
  # such as
  # papyri.info/ddbdp/bgu;7;1504
  # papyri.info/ddbdp/bgu;7;1505
  # papyri.info/ddbdp/bgu;7;1506
  def create_from_list
    id_list = params[:pn_id_list].split(/\s+/) # (/\r\n?/)
    list_is_good = true

    # get rid of any blank lines, etc
    id_list = id_list.compact.reject { |s| s.strip.empty? }

    # check that the list is in the correct form
    # clean up the ids
    id_list.map! do |id|
      # FIXME: once biblio is loaded into numbers server, remove this unless clause
      unless %r{#{NumbersRDF::NAMESPACE_IDENTIFIER}/#{BiblioIdentifier::IDENTIFIER_NAMESPACE}}o.match?(ido)
        id.chomp!('/')
        id = NumbersRDF::NumbersHelper.identifier_url_to_identifier(id)
        # check if there is a good response from the number server
        response = NumbersRDF::NumbersHelper.identifier_to_numbers_server_response(id)

        # puts id + " returned " + response.code # + response.body
        if response.code != '200'

          # bad format most likely
          id = "Numbers Server Error, Check format--> #{id}"
          list_is_good = false

        elsif !response.body.index('rdf:Description')

          # item does not exist most likely
          # puts "text is bad"
          id = "Not Found--> #{id}"
          list_is_good = false

        end
      end
      id
    end

    unless list_is_good
      # recreate list
      error_str = 'Unable to create Publication.<br />'
      id_list.each do |id|
        error_str = "#{error_str}#{id}<br />"
      end
      flash[:error] = error_str
      redirect_to action: 'advanced_create'
      return
    end

    # clean up any duplicated lines
    id_list = id_list.uniq

    publication_from_identifiers(id_list)
  end

  def submit
    @publication.with_lock do
      @publication.with_advisory_lock("submit_#{@publication.id}") do
        # prevent resubmitting...most likely by impatient clicking on submit button
        unless %w[editing new].include?(@publication.status)
          flash[:error] = 'Publication has already been submitted. Did you click "Submit" multiple times?'
          redirect_to @publication
          return
        end

        # check if we need to signup to a community
        if params[:do_community_signup] && params[:community] && params[:community][:id] != '0'
          @community = Community.find(params[:community][:id].to_s)
          unless @community.add_member(@current_user.id)
            flash[:error] = 'Unable to signup for selected community'
            redirect_to @publication
            return
          end
        end

        # check if we are submitting to a community
        # community_id = params[:community_id]
        if params[:community] && params[:community][:id]
          community_id = params[:community][:id]
          community_id.strip
          if !community_id.empty? && community_id != '0' && !community_id.nil?
            @publication.community_id = community_id
            Rails.logger.info "Publication #{@publication.id} #{@publication.title} will be submitted to #{@publication.community.format_name}"
          else
            # force community id to nil for sosol
            @publication.community_id = nil
            Rails.logger.info "Publication #{@publication.id} #{@publication.title} will be submitted to SoSOL"
          end

        else
          # force community id to 0 for sosol
          @publication.community_id = nil
        end

        # need to set id to 0
        # raise community_id

        # @comment = Comment.new( {:git_hash => @publication.recent_submit_sha, :publication_id => params[:id].to_s, :comment => params[:submit_comment].to_s, :reason => "submit", :user_id => @current_user.id } )
        # git hash is not yet known, but we need the comment for the publication.submit to add to the changeDesc
        @comment = Comment.new({ publication_id: params[:id].to_s, comment: params[:submit_comment].to_s,
                                 reason: 'submit', user_id: @current_user.id })
        @comment.save

        error_text, identifier_for_comment = @publication.submit
        if error_text == ''
          # update comment with git hash when successfully submitted
          @comment.git_hash = @publication.recent_submit_sha
          @comment.identifier_id = identifier_for_comment
          @comment.save
          expire_publication_cache
          expire_fragment(/board_publications_\d+/)
          flash[:notice] = 'Publication submitted.'
        else
          # cleanup comment that was inserted before submit completed that is no longer valid because of submit error
          cleanup_id = Comment.find(:last,
                                    conditions: { publication_id: params[:id].to_s, reason: 'submit',
                                                  user_id: @current_user.id })
          Comment.destroy(cleanup_id)
          flash[:error] = error_text
        end
        redirect_to @publication
      end
    end
  end

  # GET /publications
  # GET /publications.xml
  def index
    @branches = @current_user.repository.branches
    @branches.delete('master')

    @publications = Publication.where(owner_id: @current_user.id)
    # just give branches that don't have corresponding publications
    @branches -= @publications.map(&:branch)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @publications }
    end
  end

  def recover_branch
    @publication = Publication.find(params[:id].to_s)
    original_publication_owner_id = @publication.owner.id

    if @publication.advisory_lock_exists?("recover_branch_#{@publication.id}")
      flash[:notice] = 'Git branch recovery is already running for this publication.'
      redirect_to show
    else
      RecoverBranchJob.perform_async(@publication.id)
      flash[:notice] = 'Git branch recovery running. Check back in a few minutes.'
      redirect_to controller: 'user', action: 'dashboard', board_id: original_publication_owner_id
    end
  end

  def become_finalizer
    # TODO: make sure we don't steal it from someone who is working on it
    @publication = Publication.find(params[:id].to_s)
    original_publication_owner_id = @publication.owner.id

    if @publication.owner_type != 'Board'
      # NOTE: this can only be called on a board owned publication
      flash[:error] = "Can't change finalizer on non-board copy of publication."
      redirect_to show
    elsif @publication.advisory_lock_exists?("become_finalizer_#{@publication.id}")
      flash[:notice] = 'Another user is currently making themselves the finalizer of this publication.'
      redirect_to show
    elsif @publication.advisory_lock_exists?("finalize_#{@publication.id}")
      flash[:error] = "Can't change finalizer - finalizer's copy is already in the process of being finalized."
      redirect_to show
    else
      SendToFinalizerJob.perform_async(@publication.id, @current_user.id)
    end

    flash[:notice] = 'Finalizer change running. Check back in a few minutes.'
    redirect_to controller: 'user', action: 'dashboard', board_id: original_publication_owner_id
  end

  def finalize_review
    @publication = Publication.find(params[:id].to_s)
    @identifier = @publication.controlled_identifiers.last
    if @publication.advisory_lock_exists?("finalize_#{@publication.parent.id}")
      flash.now[:notice] = 'This publication is currently being finalized. Check back in a few minutes.'
    elsif @publication.parent.advisory_lock_exists?("become_finalizer_#{@publication.parent.id}")
      flash[:notice] =
        'Someone is already performing a make-me-finalizer action with this publication. Please check back in a few minutes.'
      redirect_to controller: 'user', action: 'dashboard', board_id: @publication.parent.owner.id
    end

    @diff = @publication.diff_from_canon
    if @diff.blank?
      flash.now[:error] = 'WARNING: Diff from canon is empty. Something may be wrong.'
    elsif @publication.needs_rename?
      identifiers_needing_rename = @publication.identifiers_needing_rename
      flash.now[:notice] =
        "Publication has one or more identifiers which need to be renamed before finalizing: #{identifiers_needing_rename.map(&:name).join(', ')}"
    end
    @is_editor_view = true
  end

  def finalize
    @publication = Publication.find(params[:id].to_s)

    if @publication.needs_rename?
      identifiers_needing_rename = @publication.identifiers_needing_rename
      flash[:error] =
        "Publication has one or more identifiers which need to be renamed before finalizing: #{identifiers_needing_rename.map(&:name).join(', ')}"
      redirect_to @publication
      return
    end

    if @publication.advisory_lock_exists?("finalize_#{@publication.parent.id}")
      flash[:error] = 'Finalization is already running for this publication. Please check back in a few minutes.'
      redirect_to controller: 'user', action: 'dashboard', board_id: @publication.parent.owner.id
    elsif @publication.parent.advisory_lock_exists?("become_finalizer_#{@publication.parent.id}")
      flash[:error] =
        'Unable to perform finalization - someone is already performing a make-me-finalizer action with this publication. Please check back in a few minutes.'
      redirect_to controller: 'user', action: 'dashboard', board_id: @publication.parent.owner.id
    else
      begin
        # Synchronous finalization, errors get presented in error flash
        # @publication.finalize(params[:comment])
        # flash[:notice] = 'Publication finalized.'
        # Asynchronous finalization, errors get sent to Airbrake
        FinalizeJob.perform_async(@publication.id, params[:comment])
        flash[:notice] = 'Finalization running. Check back in a few minutes.'
        # Need a way to do this at the correct time for async finalization?
        expire_publication_cache(@publication.creator.id)
        expire_fragment(/board_publications_\d+/)
      rescue RuntimeError => e
        flash[:error] = e.message
      end
    end

    redirect_to controller: 'user', action: 'dashboard', board_id: @publication.parent.owner.id
  end

  # GET /publications/1
  # GET /publications/1.xml
  def show
    begin
      @publication = Publication.find(params[:id].to_s)
    rescue StandardError
      flash[:error] = 'Publication not found'
      redirect_to(dashboard_url)
      return
    end
    @is_editor_view = true
    @all_comments, @xml_only_comments = @publication.get_all_comments(@publication.origin.title)

    @show_submit = allow_submit?

    # only let creator delete
    @allow_delete = @current_user.id == @publication.creator.id
    # only delete new or editing
    @allow_delete &&= (@publication.status == 'new' || @publication.status == 'editing')
    @identifier = @publication.entry_identifier

    # TODO: - if any part has been approved, do we want them to be able to delete the publication or force it to an archve? this would only happen if a board returns their part after another board has approved their part

    # find other users who are editing the same thing
    @other_user_publications = Publication.other_users(@publication.title, @current_user.id)

    determine_creatable_identifiers

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @publication }
    end
  end

  # GET /publications/1/edit
  def edit
    @publication = Publication.find(params[:id].to_s)

    redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
  end

  def edit_text
    @publication = Publication.find(params[:id].to_s)
    @identifier = DDBIdentifier.find_by(publication_id: @publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end

  def edit_meta
    @publication = Publication.find(params[:id].to_s)
    @identifier = HGVMetaIdentifier.find_by(publication_id: @publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end

  def edit_apis
    @publication = Publication.find(params[:id].to_s)
    @identifier = APISIdentifier.find_by(publication_id: @publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end

  def edit_trans
    @publication = Publication.find(params[:id].to_s)
    @identifier = HGVTransIdentifier.find_by(publication_id: @publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end

  def edit_biblio
    @publication = Publication.find(params[:id].to_s)
    @identifier = BiblioIdentifier.find_by(publication_id: @publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end

  def edit_adjacent
    # if they are on show, then need to goto first or last identifers
    if params[:current_action_name] == 'show'
      @publication = Publication.find(params[:id].to_s)
      @identifier = if params[:direction] == 'prev'
                      @publication.identifiers.last
                    else
                      @publication.identifiers.first
                    end
      redirect_to edit_polymorphic_path([@publication, @identifier])
      return
    end

    @publication = Publication.find(params[:pub_id].to_s)

    direction = if params[:direction] == 'prev'
                  -1
                else # assume next params[:direction] == 'next'
                  1
                end

    @identifier = Identifier.find(params[:id_id].to_s)
    current_identifier_class = @identifier.class
    current_index = @publication.identifiers.index(@identifier)

    return_index = current_index + direction
    if return_index.negative?
      redirect_to @publication
      return
      # or for loop over without overview
      # return_index = @publication.identifiers.length - 1
    elsif return_index >= @publication.identifiers.length
      redirect_to @publication
      return
      # or for loop over without overview
      # return_index = 0
    end

    @identifier = @publication.identifiers[return_index]
    if @identifier.instance_of?(current_identifier_class)
      # /publications/1/identifiers/1/action
      redirect_to controller: params[:current_controller_name], action: params[:current_action_name],
                  id: @identifier.id, publication_id: params[:pub_id]
    else
      # if no longer the same class, we can't assume that the next class as the same edit methods
      redirect_to edit_polymorphic_path([@publication, @identifier])
    end
  end

  def create_from_selector
    identifier_class = params[:IdentifierClass]
    collection = params["#{identifier_class}CollectionSelect".intern]
    volume = params[:volume_number]
    document = params[:document_number]

    volume = '' if volume == 'Volume Number'

    if (document == 'Document Number') || document.blank?
      flash[:error] = 'Error creating publication: you must specify a document number'
      redirect_to dashboard_url
      return
    end

    case identifier_class
    when 'DDBIdentifier'
      document_path = [collection, volume, document].join(';')
    when 'HGVIdentifier'
      collection = collection.tr(' ', '_')
      document_path = if volume.blank?
                        [collection, document].join('_')
                      else
                        [collection, volume, document].join('_')
                      end
    when 'APISIdentifier'
      document_path = [collection, 'apis', document].join('.')
    end

    namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE

    identifier = [NumbersRDF::NAMESPACE_IDENTIFIER, namespace, document_path].join('/')

    related_identifiers = if identifier_class == 'HGVIdentifier'
                            NumbersRDF::NumbersHelper.collection_identifier_to_identifiers(identifier)
                          else
                            NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier)
                          end

    publication_from_identifier(identifier, related_identifiers)
  end

  def vote
    # NOTE: that votes will go with the boards copy of the pub and identifiers
    #  vote history will also be recorded in the comment of the origin pub and identifier

    # fails - if not pub found ie race condition of voting on reject or graffiti
    begin
      @publication = Publication.find(params[:id].to_s)
    rescue StandardError
      flash[:warning] = 'Publication not found - voting is over for this publications.'
      redirect_to(dashboard_url)
      return
    end

    # fails - vote choice not given
    if params[:vote].blank? || params[:vote][:choice].blank?
      flash[:error] = 'You must select a vote choice.'

      redirect_to edit_polymorphic_path([@publication,
                                         params[:vote].blank? ? @publication.entry_identifier : Identifier.find(params[:vote][:identifier_id])])
      return
    end

    # fails - voting is over
    if @publication.status != 'voting'
      flash[:warning] = 'Voting is over for this publication.'
      redirect_to @publication
      return
    end

    # fails - publication not in correct ownership
    if @publication.owner_type != 'Board'
      # we have a problem since no one should be voting on a publication if it is not in theirs
      flash[:error] = 'You do not have permission to vote on this publication which you do not own!'
      # kind a harsh but send em back to their own dashboard
      redirect_to dashboard_url
      return
    end

    Vote.transaction do
      @publication.lock!
      # NOTE: that votes go to the publication's identifier
      @vote = Vote.new(vote_params)
      vote_identifier = @vote.identifier.lock!
      @vote.user_id = @current_user.id
      @vote.board_id = @publication.owner_id

      @comment = Comment.new
      @comment.comment = "#{@vote.choice} - #{params[:comment][:comment]}"
      @comment.user = @current_user
      @comment.reason = 'vote'
      # use most recent sha from identifier
      @comment.git_hash = vote_identifier.get_recent_commit_sha
      # associate comment with original identifier/publication
      @comment.identifier = vote_identifier.origin
      @comment.publication = @vote.publication.origin

      # double check that they have not already voted
      # has_voted = vote_identifier.votes.find_by_user_id(@current_user.id)
      has_voted = @publication.user_has_voted?(@current_user.id)
      unless has_voted
        @comment.save!
        @vote.save!
        # invalidate their cache since an action may have changed its status
        expire_publication_cache(@publication.creator.id)
        expire_fragment(/board_publications_\d+/)
      end
    end

    begin
      # see if publication still exists
      Publication.find(params[:id].to_s)
      redirect_to @publication
      nil
    rescue StandardError
      # voting destroyed publication so go to the dashboard
      redirect_to dashboard_url
      nil
    end
  end

  def confirm_archive
    @publication = Publication.find(params[:id].to_s)
  end

  def confirm_archive_all
    if @current_user.id.to_s != params[:id]
      if @current_user.developer || @current_user.admin
        flash.now[:warning] = 'You are going to archive publications you do not own as either a developer or an admin.'
      else
        flash[:error] = 'You are only allowed to archive your publications.'
        redirect_to dashboard_url
      end
    end
    @publications = Publication.where(owner_id: params[:id].to_s, owner_type: 'User', status: 'committed',
                                      creator_id: params[:id].to_s, parent_id: nil).order(updated_at: :desc)
  end

  def archive
    archive_pub(params[:id].to_s)
    expire_publication_cache
    redirect_to @publication
  end

  # - loop thru all the committed publication ids and archive each one
  # - clear the cache
  # - go to the dashboard
  def archive_all
    params[:pub_ids].each do |id|
      archive_pub(id)
    end
    expire_publication_cache
    redirect_to dashboard_url
  end

  def confirm_withdraw
    @publication = Publication.find(params[:id].to_s)
  end

  def withdraw
    @publication = Publication.find(params[:id].to_s)
    pub_name = @publication.title
    @publication.withdraw

    # send email to the user informing them of the withdraw
    # EmailerMailer.deliver_send_withdraw_note(@publication.creator.email, @publication.title )
    address = @publication.creator.email
    if address && address.strip != ''
      begin
        EmailerMailer.withdraw_note(address, @publication.title).deliver
      rescue StandardError => e
        Rails.logger.error("Error sending withdraw email: #{e.class}, #{e}")
      end
    end

    flash[:notice] = "Publication #{pub_name} was successfully withdrawn."
    expire_publication_cache
    redirect_to dashboard_url
  end

  def confirm_delete
    @publication = Publication.find(params[:id].to_s)
  end

  # DELETE
  def destroy
    @publication = Publication.find(params[:id].to_s)
    pub_name = @publication.title
    @publication.destroy

    flash[:notice] = "Publication #{pub_name} was successfully deleted."
    expire_publication_cache
    respond_to do |format|
      format.html { redirect_to dashboard_url }
    end
  end

  def master_list
    if @current_user.developer
      @publications = Publication.all
    else
      redirect_to dashboard_url
    end
  end

  protected

  def find_publication
    @publication ||= Publication.lock(true).find(params[:id].to_s)
  end

  def ownership_guard
    find_publication
    unless @publication.mutable_by?(@current_user)
      flash[:error] = 'Operation not permitted.'
      redirect_to dashboard_url
    end
  end

  def allow_submit?
    # check if publication has been changed by user
    allow = @publication.modified?

    # only let creator submit
    allow &&= @publication.creator_id == @current_user.id

    # only let user submit, don't let a board member submit
    allow &&= @publication.owner_type == 'User'

    # dont let user submit if already submitted, or committed etc..
    allow &&= ((@publication.status == 'editing') || (@publication.status == 'new'))

    return allow

    # below bypassed until we have return mechanism in place

    # check if any part of the publication is still being edited (ie not already submitted)
    if allow # something has been modified so lets see if they can submit it
      allow = false # dont let them submit unless something is in edit status
      @publication.identifiers.each do |identifier|
        allow = true if identifier.nil? || identifier.status == 'editing'
      end
    end
    allow
  end

  def publication_from_identifiers(identifiers)
    new_title = "Batch_#{Time.zone.now.strftime('%d%b%Y_%H%M')}"
    publication_from_identifier('unused_place_holder', identifiers, new_title)

    #       #do we need to check for conflicts with the batches?
    #       #might be able to modify publication_from_identifier
    #       #where to get title? make them up based on time for now
    #       new_title = 'Batch_' + Time.now.strftime("%d%b%Y_%H%M") #12Jan2011_2359
    #       #puts new_title
    #         @publication = Publication.new()
    #         @publication.owner = @current_user
    #         @publication.creator = @current_user
    #
    #         @publication.populate_identifiers_from_identifiers(
    #           identifiers, new_title)
    #
    #         if @publication.save!
    #           @publication.branch_from_master
    #
    #           # need to remove repeat against publication model
    #           e = Event.new
    #           e.category = "started editing"
    #           e.target = @publication
    #           e.owner = @current_user
    #           e.save!
    #
    #           flash[:notice] = 'Publication was successfully created.'
    #           expire_publication_cache
    #           redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    #         else
    #           flash[:notice] = 'Error creating publication'
    #           redirect_to dashboard_url
    #         end
  end

  def publication_from_identifier(identifier, related_identifiers = nil, optional_title = nil)
    Rails.logger.info("Identifier: #{identifier}")
    Rails.logger.info("Related identifiers: #{related_identifiers.inspect}")

    conflicting_identifiers = []

    if related_identifiers.nil?
      flash[:error] = 'Error creating publication: publication not found'
      redirect_to dashboard_url
      return
    end

    related_identifiers.each do |relid|
      possible_conflicts = Identifier.where(name: relid).includes(:publication)
      actual_conflicts = possible_conflicts.select do |pc|
        (pc.publication && (pc.publication.owner == @current_user) && %w[archived
                                                                         finalized].exclude?(pc.publication.status))
      end
      conflicting_identifiers += actual_conflicts
    end

    if related_identifiers.length.zero?
      flash[:error] = 'Error creating publication: publication not found'
      redirect_to dashboard_url
      return
    elsif conflicting_identifiers.length.positive?
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
        # TODO: should set "archived" and take approp action here instead
        # conflicting_publication.destroy
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
    @publication = Publication.new
    @publication.owner = @current_user
    @publication.creator = @current_user
    @publication.populate_identifiers_from_identifiers(
      related_identifiers, optional_title
    )
    if @publication.save!
      @publication.branch_from_master

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
    # end
  end

  def expire_publication_cache(user_id = @current_user.id)
    expire_fragment(controller: 'user', action: 'dashboard', part: "your_publications_#{user_id}")
  end

  def archive_pub(pub_id)
    @publication = Publication.find(pub_id)
    if (@current_user.id == @publication.owner_id) || @current_user.developer || @current_user.admin
      @publication.archive
    end
  end

  private

  def determine_creatable_identifiers
    @creatable_identifiers = @publication.creatable_identifiers
  end

  def publication_params
    params.require(:publication)
  end

  def vote_params
    params.require(:vote).permit(:publication_id, :identifier_id, :user_id, :board_id, :choice)
  end
end
