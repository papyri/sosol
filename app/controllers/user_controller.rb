class UserController < ApplicationController
  # #layout 'site'
  # layout 'header_footer'
  before_action :authorize, except: %i[signin signout show info help all_users_links]

  def signout
    sign_out current_user if current_user.present?
    reset_session
    redirect_to controller: :welcome, action: 'index'
  end

  def leave_community
    @community = Community.find(params[:com_id])
  end

  # default view of stats is only for the current user, see below for all users
  def usage_stats
    @comments = User.stats(@current_user.id)
    @votes = @comments.select { |x| x['reason'] == 'vote' }
    @submits = @comments.select { |x| x['reason'] == 'submit' }
    @finalizings = @comments.select { |x| x['reason'] == 'finalizing' }
  end

  def all_users_links
    @users = User.order(full_name: :asc)
  end

  # Gets info for the current user in json format.
  # *Returns*
  #- User model for the current user.
  #- nil if no user is logged in.
  def info
    render json: @current_user.nil? ? {} : @current_user
  end

  # view of stats for the user id page shown with optional date limitation
  def refresh_usage
    @users = [User.find_by_id(params[:save_user_id])]
    @comments = User.stats(@users.first.id)

    # default to 1 year ago if date value not entered
    if params[:date_value].blank?
      params[:date_value] = '365'
    else
      # if date value not numeric
      unless params[:date_value].strip.match(/[^\d]+/).nil?
        @calc_date = Date.tomorrow
        flash.now[:error] = 'Please enter a whole number value for the usage range.'
        render 'usage_stats'
        return
      end
    end

    case params[:date_range]
    when 'day'
      @calc_date = Date.today - params[:date_value].to_i
    when 'month'
      @calc_date = Date.today << params[:date_value].to_i
    when 'year'
      calc_months = params[:date_value].to_i * 12
      @calc_date = Date.today << calc_months
    end

    @votes = @comments.select { |x| x['reason'] == 'vote' && x['created_at'] > @calc_date }
    @submits = @comments.select { |x| x['reason'] == 'submit' && x['created_at'] > @calc_date }
    @finalizings = @comments.select { |x| x['reason'] == 'finalizing' && x['created_at'] > @calc_date }
    flash.now[:notice] = "Usage since #{@calc_date}"
    render 'usage_stats'
  end

  # default view of stats for the user name entered/linked to
  def show
    @users = [User.find_by_name(params[:user_name])]
    if !@users.compact.empty?
      @comments = User.stats(@users.first.id)
      @votes = @comments.select { |x| x['reason'] == 'vote' }
      @submits = @comments.select { |x| x['reason'] == 'submit' }
      @finalizings = @comments.select { |x| x['reason'] == 'finalizing' }
      @calc_date = ''
      respond_to do |format|
        format.html do
          render 'usage_stats'
          return
        end
        format.json { render json: @users.first }
        format.xml  { render xml: @users.first }
      end
    else
      flash[:error] = 'User not found.'
      redirect_to dashboard_url
    end
  end

  def account
    @identifiers = @current_user.user_identifiers if @current_user
  end

  def signin
    reset_session
    if (ENV['RAILS_ENV'] == 'development') && @current_user.nil? && params[:developer]
      developer = User.find_by_name('developer')
      if developer.nil?
        developer = User.create(name: 'developer', email: 'developer@example.com',
                                full_name: 'Development User')
        developer.save!
      end
      session[:user_id] = developer.id
      session[:identifier] = nil
      redirect_to controller: 'welcome', action: 'index'
    end
  end

  def developer
    unless @current_user.developer
      redirect_to dashboard_url
      return
    end
    @boards = Board.all
  end

  # Entry point for dashboards. Will redirect to board_dashboard if given board_id. Will redirect to user_dashboard if no board_id. Will render old dashboard if given old as parameter.
  def dashboard
    # don't let someone who isn't signed in go to the dashboard
    if @current_user.nil?
      # keep any flashes as we were likely redirected here and rails 3 only
      # keeps through one redirect by default
      flash.keep

      redirect_to controller: 'user', action: 'signin'
      return
    end

    # show the "new" dashboard unless the specfically request the old version
    unless params[:old]

      # keep any flashes as we were likely redirected here and rails 3 only
      # keeps through one redirect by default
      flash.keep

      # redirect to new dashboards
      if params[:board_id]
        redirect_to action: 'board_dashboard', board_id: params[:board_id]
      else
        redirect_to action: 'user_dashboard'
      end
      return

    end

    # show the old dashboard

    # below selects publications to show in standard user data section of dashboard
    unless fragment_exist?(action: 'dashboard', part: "your_publications_#{@current_user.id}")
      @publications = Publication.where.not(status: 'archived').where(owner_id: @current_user.id,
                                                                      creator_id: @current_user.id, owner_type: 'User', parent_id: nil).includes(identifiers: [:votes]).order(updated_at: :desc)
    end

    unless fragment_exist?(action: 'dashboard', part: "board_publications_#{@current_user.id}")
      # below selects publications current user is responsible for finalizing to show in board section of dashboard
      @board_final_pubs = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                            status: 'finalizing').includes(identifiers: [:votes]).order(updated_at: :desc)

      @boards = @current_user.boards.ranked
    end

    if !fragment_exist?(action: 'dashboard',
                        part: 'events_list_time') || (Time.now > (read_fragment(
                          action: 'dashboard', part: 'events_list_time'
                        ) + 60))
      write_fragment({ action: 'dashboard', part: 'events_list_time' }, Time.now)
      expire_fragment(action: 'dashboard', part: 'events_list')
    end

    unless fragment_exist?(action: 'dashboard', part: 'events_list')
      @events = Event.order(created_at: :desc).limit(25).includes(:owner, :target).load
    end

    render layout: 'site'
    return

    if params[:board_id]
      # @boards = @current_user.boards.ranked_by_community_id(params[:board_id])
      @boards = Board.find(params[:board_id])

      render 'dashboard_board'
      return
    end

    dashboard_type = params[:dashboard_type]
    if dashboard_type
      # puts dashboard_type
      if dashboard_type == 'user'
        render 'dashboard_user'
        return
      end
      if dashboard_type == 'board'
        render 'dashboard_board'
        nil
      end
    end

    # render "dashboard_user"
  end

  # Finds publications created by current user and are not part of a community.
  def user_dashboard
    # assuming 4 find calls faster than the above, then splits

    @submitted_publications = Publication.where(owner_id: @current_user.id, community_id: nil, owner_type: 'User',
                                                creator_id: @current_user.id, parent_id: nil, status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
    @editing_publications = Publication.where(owner_id: @current_user.id, community_id: nil, owner_type: 'User',
                                              creator_id: @current_user.id, parent_id: nil, status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
    @new_publications = Publication.where(owner_id: @current_user.id, community_id: nil, owner_type: 'User',
                                          creator_id: @current_user.id, parent_id: nil, status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
    @committed_publications = Publication.where(owner_id: @current_user.id, community_id: nil, owner_type: 'User',
                                                creator_id: @current_user.id, parent_id: nil, status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)

    @show_events = true
  end

  # /peep_user_dashboard/1              dashboard for user with user id #1
  # /peep_user_dashboard/1/submitted    dashboard for all submitted publications of user with user id #1
  # /peep_user_dashboard/1/11           dashboard for publication with id 11 of user with user id #1
  def peep_user_dashboard
    if current_user_is_master_admin?
      user_id = params[:user_id]
      status = nil
      publication_id = nil

      case params[:publication]
      when /\A\d+\Z/
        publication_id = params[:publication]
      when /\A[^\d]+\Z/
        status = params[:publication]
      end

      if status
        case status
        when 'submitted'
          @submitted_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                      creator_id: user_id, parent_id: nil, status: status).includes(identifiers: [:votes]).order(updated_at: :desc)
        when 'editing'
          @editing_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                    creator_id: user_id, parent_id: nil, status: status).includes(identifiers: [:votes]).order(updated_at: :desc)
        when 'new'
          @new_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                creator_id: user_id, parent_id: nil, status: status).includes(identifiers: [:votes]).order(updated_at: :desc)
        when 'committed'
          @committed_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                      creator_id: user_id, parent_id: nil, status: status).includes(identifiers: [:votes]).order(updated_at: :desc)
        when 'finalizing'
          @finalizing_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                       creator_id: user_id, parent_id: nil, status: status).includes(identifiers: [:votes]).order(updated_at: :desc)
        end
      elsif publication_id
        @submitted_publications = Publication.where(owner_id: user_id, id: publication_id, community_id: nil,
                                                    owner_type: 'User', creator_id: user_id, parent_id: nil).includes(identifiers: [:votes]).order(updated_at: :desc)
      else
        @submitted_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                    creator_id: user_id, parent_id: nil, status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
        @editing_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                  creator_id: user_id, parent_id: nil, status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
        @new_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                              creator_id: user_id, parent_id: nil, status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
        @committed_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                    creator_id: user_id, parent_id: nil, status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)
        @finalizing_publications = Publication.where(owner_id: user_id, community_id: nil, owner_type: 'User',
                                                     creator_id: user_id, parent_id: nil, status: 'finalizing').includes(identifiers: [:votes]).order(updated_at: :desc)
      end

      @show_events = true

      render 'user_dashboard'
    else
      flash[:warning] = 'Invalid Access.'
      redirect_to(dashboard_url)
    end
  end

  # Finds publications created by the current user and are part of the specified community.
  def user_community_dashboard
    cid = params[:community_id]
    @submitted_publications = Publication.where(owner_id: @current_user.id, community_id: cid,
                                                owner_type: 'User', creator_id: @current_user.id, parent_id: nil, status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
    @editing_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                              creator_id: @current_user.id, parent_id: nil, status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
    @new_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                          creator_id: @current_user.id, parent_id: nil, status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
    @committed_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                                creator_id: @current_user.id, parent_id: nil, status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)

    @community = Community.find_by_id(cid)
    render 'user_dashboard'
  end

  # Shows all publications for the current user (excepting archived status).
  def user_complete_dashboard
    @submitted_publications = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                                status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
    @editing_publications = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                              status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
    @new_publications = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                          status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
    @committed_publications = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                                status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)
    @finalizing_publications = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                                 status: 'finalizing').includes(identifiers: [:votes]).order(updated_at: :desc)

    render 'user_dashboard'
  end

  # Shows dashboard for the current user's board using the specified board_id.
  def board_dashboard
    @board = Board.find_by_id(params[:board_id])

    # get publications for the member to finalize
    @board_final_pubs = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                          status: 'finalizing').includes(identifiers: [:votes]).order(updated_at: :desc)
    @finalizing_publications = @board_final_pubs.collect do |p|
      !p.parent.nil? && p.parent.owner == @board ? p : nil
    end.compact

    # get publications that have been approved
    # @approved_publications = @board.publications.collect{|p| p.status == "approved" ? p : nil}.compact
    @approved_publications = Publication.where(owner_id: @board.id, owner_type: 'Board',
                                               status: 'approved').includes(identifiers: [:votes]).order(updated_at: :desc).to_a

    # remove approved publications if in the finalizer list
    @finalizing_publications.each do |fp|
      # remove it from the list of approved publications
      @approved_publications.reject! do |ap|
        fp.origin == ap.origin
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.debug("UserController#board_dashboard ActiveRecord::RecordNotFound while removing approved publications: #{e.inspect}")
        false
      end
    end

    # biblio voting stacked up and created huge problems (e.g. running out of heap), so
    # we now paginate voting items 50 at a time.
    @offset = if params[:offset]
                Integer(params[:offset])
              else
                0
              end
    @count = Publication.where(owner_id: @board.id, owner_type: 'Board', status: 'voting').count

    # find all pubs that are still in voting phase
    board_voting_publications = Publication.where(owner_id: @board.id, owner_type: 'Board',
                                                  status: 'voting').includes(identifiers: [:votes]).order(updated_at: :desc).offset(@offset).limit(50).to_a
    # find all pubs that the user needs to review
    @needs_reviewing_publications = board_voting_publications.collect  do |p|
      needs_review = false
      p.identifiers.each do |id|
        needs_review = true if id.needs_reviewing?(@current_user.id)
      end
      needs_review ? p : nil
    end.compact

    @member_already_voted_on = if @needs_reviewing_publications.nil?
                                 board_voting_publications
                               else
                                 board_voting_publications - @needs_reviewing_publications
                               end

    # move publications with votes to the front of the array
    voted_indices = @needs_reviewing_publications.to_enum(:each_index).select do |i|
      @needs_reviewing_publications[i].votes.length.positive?
    end
    voted_indices.each { |index| @needs_reviewing_publications.unshift(@needs_reviewing_publications.delete_at(index)) }

    # set so the correct tab will be active
    @current_board = @board
    # render :layout => 'header_footer'
  end

  def archives
    if params[:board_id]
      @board = Board.find_by_id(params[:board_id])
      @publications = @board.publications.where(status: 'archived').includes(:identifiers).order(updated_at: :desc)
    else
      @publications = Publication.where(owner_id: @current_user.id, owner_type: 'User',
                                        creator_id: @current_user.id, status: 'archived', parent_id: nil).includes(:identifiers).order(updated_at: :desc)
    end
  end

  def update_personal
    # only let current user change this data
    if @current_user.id != params[:id].to_i
      flash[:warning] = 'Invalid Access.'

      redirect_to(dashboard_url) # just send them back to their own dashboard...side effects here?
      return
    end

    @user = User.find(params[:id])

    begin
      user_params = params[:user].slice(:full_name, :affiliation, :email, :email_opt_out)

      if user_params.present? && user_params.is_a?(Hash)
        @user.update(user_params)
        flash[:notice] = 'User was successfully updated.'
      else
        flash[:error] = 'Error occured - user was not updated.'
      end
      redirect_to controller: 'user', action: 'account'
    rescue StandardError => e
      flash[:error] = 'Error occured - user was not updated.'
      redirect_to controller: 'user', action: 'account'
    end
  end

  def current_user_is_master_admin?
    unless @current_user.is_master_admin
      flash[:warning] = 'Invalid Access.'
      redirect_to(dashboard_url) # just send them back to their own dashboard...side effects here?
      return false
    end

    true
  end

  # Admin Settings allow certain rights to these groups.
  #
  #
  # Master Admin:
  #   Can set all user admin rights
  #
  # Community Master Admin:
  #   they can create destroy communities, pick community admins
  #
  # Community Admins:
  #   (note these are set on the commuity page not via user admins)
  #   can edit their communities
  #
  # Admin:
  #   Setup etc. boards
  #   Can email all users
  #
  # Developer:
  #   Extra views with debugging info.
  #

  # Admin Settings allow certain rights to these groups.
  #- Master Admin:
  #  Can set all user admin rights
  #- Community Master Admin:
  #  Can create, edit & destroy any community, pick community admins
  #- Community Admins:
  #  Can edit & destroy certain communities (note these are set on the commuity page not via user admins)
  #- Admin:
  #  Setup etc. boards
  #  Can email all users
  #- Developer:
  #  Extra views with debugging info.

  def admin
    # shows whatever they have the right to administer
  end

  def index_user_admins
    @users = User.all if current_user_is_master_admin?
  end

  def edit_user_admins
    if current_user_is_master_admin?
      @user = User.find_by_id(params[:user_id])
    else
      flash[:warning] = 'You do not have permission to edit user admins.'
      redirect_to dashboard_url
    end
  end

  def update_admins
    if current_user_is_master_admin?
      @user = User.find(params[:id])

      begin
        user_params = params[:user].slice(:is_master_admin, :is_community_master_admin, :admin, :developer)

        @user.update(user_params)
        flash[:notice] = 'User was successfully updated.'
        redirect_to controller: 'user', action: 'index_user_admins'
      rescue StandardError => e
        flash[:error] = 'Error occured - user was not updated.'
        redirect_to controller: 'user', action: 'index_user_admins'
      end
    end
  end

  def create_email_everybody
    unless @current_user.admin
      flash[:error] = 'Only Admin Users can send an email to all SoSOL users.'
      redirect_to dashboard_url
      nil
    end
  end

  def email_everybody
    unless @current_user.admin
      flash[:error] = 'Only Admin Users can create an email to all SoSOL users.'
      redirect_to dashboard_url
      return
    end
    if params[:email_subject].gsub(/^\s+|\s+$/, '') == '' || params[:email_content].gsub(/^\s+|\s+$/, '') == ''
      flash[:notice] = 'Email subject and content are both required.'
      # redirect_to :controller => "user", :action => "create_email_everybody"
      redirect_to sendmsg_url
      return
    end

    User.compose_email(params[:email_subject], params[:email_content])

    flash[:notice] = 'Email to all users was successfully sent.'
    redirect_to dashboard_url
  end

  # Collects and downloads zip file with all of the publications of the given status and community (or PE if no community).
  def download_by_status
    require 'zip'
    require 'zip/filesystem'

    status_wanted = params[:status] || 'unknown' # "committed"
    # only let them download status that are accessable
    unless %w[new editing submitted committed].include? status_wanted
      # status_wanted = "committed"
      flash[:error] = "#{status_wanted} status is not downloadable."
      redirect_to dashboard_url
      return
    end

    cid = params[:community_id] || nil
    @community = Community.find_by_id(cid) if cid

    @publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                      creator_id: @current_user.id, parent_id: nil, status: status_wanted).includes(identifiers: [:votes]).order(updated_at: :desc)

    t = Tempfile.new("publication_download_#{@current_user.name}-#{request.remote_ip}")

    Zip::OutputStream.open(t.path) do |zos|
      @publications.each do |publication|
        publication.identifiers.each do |id|
          # raise id.title + " ... " + id.name + " ... " + id.title.gsub(/\s/,'_')

          # simple paths for just this pub
          # zos.put_next_entry( id.class::FRIENDLY_NAME + "-" + id.title.gsub(/\s/,'_') + ".xml")

          # full path as used in repo
          zos.put_next_entry(id.to_path)

          zos << id.xml_content
        end
      end
    end

    # End of the block  automatically closes the zip? file.

    # The temp file will be deleted some time...
    # add com name
    community = 'PE'
    community = @community.format_name if @community
    filename = "#{@current_user.name}_#{community}_#{status_wanted}_#{Time.now}.zip"
    send_file t.path, type: 'application/zip', disposition: 'attachment', filename: filename

    t.close
  end

  # Combines all of the user's publications (for PE or the given board, regardless of status) into one download.
  def download_user_publications
    require 'zip'
    require 'zip/filesystem'

    cid = params[:community_id]
    @submitted_publications = Publication.where(owner_id: @current_user.id, community_id: cid,
                                                owner_type: 'User', creator_id: @current_user.id, parent_id: nil, status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
    @editing_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                              creator_id: @current_user.id, parent_id: nil, status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
    @new_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                          creator_id: @current_user.id, parent_id: nil, status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
    @committed_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                                creator_id: @current_user.id, parent_id: nil, status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)

    @community = Community.find_by_id(cid)

    @publications = @submitted_publications + @editing_publications + @new_publications + @committed_publications
    t = Tempfile.new("publication_download_#{@current_user.name}-#{request.remote_ip}")

    Zip::OutputStream.open(t.path) do |zos|
      @publications.each do |publication|
        publication.identifiers.each do |id|
          # full path as used in repo
          zos.put_next_entry(id.to_path)
          zos << id.xml_content
        end
      end
    end

    # End of the block  automatically closes the zip? file.

    # The temp file will be deleted some time...
    community = 'PE'
    community = @community.format_name if @community
    filename = "#{@current_user.name}_#{community}_#{Time.now}.zip"
    send_file t.path, type: 'application/zip', disposition: 'attachment', filename: filename

    t.close
  end

  # Determines which combos of boards & publication status' exist so we can ask the user which one they want to download.
  def download_options
    # has become overkill for current method, really only need to see if any of these publications exists, dont need the whole list
    cid = nil
    @submitted_publications = Publication.where(owner_id: @current_user.id, community_id: cid,
                                                owner_type: 'User', creator_id: @current_user.id, parent_id: nil, status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
    @editing_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                              creator_id: @current_user.id, parent_id: nil, status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
    @new_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                          creator_id: @current_user.id, parent_id: nil, status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
    @committed_publications = Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                                                creator_id: @current_user.id, parent_id: nil, status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)

    # @community = Community.find_by_id(cid)

    @communities = {}
    if @current_user.community_memberships&.length&.positive?
      @current_user.community_memberships.each do |community|
        # raise community.id.to_s
        cid = community.id
        # raise community.name
        @communities[cid] = {}
        @communities[cid][:id] = cid
        @communities[cid][:name] = community.format_name
        @communities[cid][:submitted_publications] =
          Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                            creator_id: @current_user.id, parent_id: nil, status: 'submitted').includes(identifiers: [:votes]).order(updated_at: :desc)
        @communities[cid][:editing_publications] =
          Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                            creator_id: @current_user.id, parent_id: nil, status: 'editing').includes(identifiers: [:votes]).order(updated_at: :desc)
        @communities[cid][:new_publications] =
          Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                            creator_id: @current_user.id, parent_id: nil, status: 'new').includes(identifiers: [:votes]).order(updated_at: :desc)
        @communities[cid][:committed_publications] =
          Publication.where(owner_id: @current_user.id, community_id: cid, owner_type: 'User',
                            creator_id: @current_user.id, parent_id: nil, status: 'committed').includes(identifiers: [:votes]).order(updated_at: :desc)
      end
    end
  end
end
