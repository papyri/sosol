class UserController < ApplicationController
  ##layout 'site'
  #layout 'header_footer'
  before_filter :authorize, :except => [:signin, :signout, :show, :info, :help, :all_users_links]

  def signout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
  end

  def leave_community
    @community = Community.find(params[:com_id])
  end

  #default view of stats is only for the current user, see below for all users
  def usage_stats
    @comments = User.stats(@current_user.id)
    @votes = @comments.select{|x| x["reason"] == 'vote'}
    @submits = @comments.select{|x| x["reason"] == 'submit'}
    @finalizings = @comments.select{|x| x["reason"] == 'finalizing'}
  end

  def all_users_links
    @users = User.find(:all, :order => "full_name ASC")
  end

  #Gets info for the current user in json format.
  #*Returns*
  #- User model for the current user.
  #- nil if no user is logged in.
  def info
    render :json => @current_user.nil? ? {} : @current_user
  end

  #view of stats for the user id page shown with optional date limitation
  def refresh_usage
    @users = [User.find_by_id(params[:save_user_id])]
    @comments = User.stats(@users.first.id)

    #default to 1 year ago if date value not entered
    if params[:date_value].blank?
      params[:date_value] = '365'
    else
      #if date value not numeric
      if !params[:date_value].strip.match(/[^\d]+/).nil?
        @calc_date = Date.tomorrow
        flash.now[:error] = "Please enter a whole number value for the usage range."
        render "usage_stats"
        return
      end
    end

    case params[:date_range]
      when "day"
        @calc_date = Date.today - params[:date_value].to_i
      when "month"
        @calc_date = Date.today << params[:date_value].to_i
      when "year"
        calc_months = params[:date_value].to_i * 12
        @calc_date = Date.today << calc_months
    end

    @votes = @comments.select{|x| x["reason"] == 'vote' && x["created_at"] > @calc_date}
    @submits = @comments.select{|x| x["reason"] == 'submit' && x["created_at"] > @calc_date}
    @finalizings = @comments.select{|x| x["reason"] == 'finalizing' && x["created_at"] > @calc_date}
    flash.now[:notice] = "Usage since #{@calc_date}"
    render "usage_stats"
  end

  #default view of stats for the user name entered/linked to
  # json and xml formats just return user human name and affiliation
  def show
    @users = [User.find_by_name(params[:user_name])]
    if !@users.compact.empty?
      @comments = User.stats(@users.first.id)
      @votes = @comments.select{|x| x["reason"] == 'vote'}
      @submits = @comments.select{|x| x["reason"] == 'submit'}
      @finalizings = @comments.select{|x| x["reason"] == 'finalizing'}
      @calc_date = ''
      respond_to do |format|
        format.html { render "usage_stats"; return }
        format.json { render :json => { 
          :human_name => @users.first.human_name,
          :affiliation => @users.first.affiliation }}
        format.xml  { render :xml => {
          :human_name => @users.first.human_name,
          :affiliation => @users.first.affiliation }}
      end
    else
      flash[:error] = "User not found."
      redirect_to dashboard_url
    end
  end

  def account
    if @current_user
      @identifiers = @current_user.user_identifiers
      @collection = CollectionsHelper::make_data_link(CollectionsHelper::make_collection(@current_user))
    end
    SiteHelper::is_perseids? ? render 'user_account_perseids' : 'user_account'
  end

  def signin
    SiteHelper::is_perseids? ? render 'signin_perseids' : 'signin'
  end

  def terms
     flash[:notice] = "Please read and accept the terms of service."
  end

  def developer
    if !@current_user.developer
      redirect_to dashboard_url
      return
    end
    @boards = Board.find(:all)
  end


  #Entry point for dashboards. Will redirect to board_dashboard if given board_id. Will redirect to user_dashboard if no board_id. Will render old dashboard if given old as parameter.
  def dashboard
    #don't let someone who isn't signed in go to the dashboard
    if @current_user == nil
      # keep any flashes as we were likely redirected here and rails 3 only
      # keeps through one redirect by default
      flash.keep

      redirect_to :controller => "user", :action => "signin"
      return
    end

    #show the "new" dashboard unless the specfically request the old version
    unless params[:old]

      # keep any flashes as we were likely redirected here and rails 3 only
      # keeps through one redirect by default
      flash.keep

      #redirect to new dashboards
      if params[:board_id]
        redirect_to :action => "board_dashboard", :board_id => params[:board_id]
        return
      else
        redirect_to :action => "user_dashboard"
        return
      end

    end

    #show the old dashboard

    #below selects publications to show in standard user data section of dashboard
    #@publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => "owner_type = 'User' AND owner_id = creator_id AND parent_id is null", :include => :identifiers)

    unless fragment_exist?(:action => 'dashboard', :part => "your_publications_#{@current_user.id}")
      @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => "owner_type = 'User' AND status != 'archived' AND owner_id = creator_id AND parent_id is null", :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      #could not find valid format for status not equal to 'archive' in below statement so resorted to older format above
      #@publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    end

    unless fragment_exist?(:action => 'dashboard', :part => "board_publications_#{@current_user.id}")
      #below selects publications current user is responsible for finalizing to show in board section of dashboard
      #@board_final_pubs = Publication.find_all_by_owner_id(@current_user.id, :conditions => "owner_type = 'User' AND status = 'finalizing'", :include => :identifiers, :order => "updated_at DESC")
      @board_final_pubs = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :status => 'finalizing'}, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

      @boards = @current_user.boards.sorted_by_community_and_ranked
      #or do we want to use the creator id?
      #@publications = Publication.find_all_by_creator_id(@current_user.id, :include => :identifiers)
    end

    if !fragment_exist?(:action => 'dashboard', :part => 'events_list_time') || (Time.now > (read_fragment(:action => 'dashboard', :part => 'events_list_time') + 60))
      write_fragment({:action => 'dashboard', :part => 'events_list_time'}, Time.now)
      expire_fragment(:action => 'dashboard', :part => 'events_list')
    end

    unless fragment_exist?(:action => 'dashboard', :part => 'events_list')
      @events = Event.find(:all, :order => "created_at DESC", :limit => 25,
                           :include => [:owner, :target])[0..24]
    end


    render :layout =>'site'
    return

    if params[:board_id]
      #@boards = @current_user.boards.ranked_by_community_id(params[:board_id])
      @boards = Board.find(params[:board_id])

      render "dashboard_board"
      return
    end

    dashboard_type = params[:dashboard_type]
    if (dashboard_type)
      #puts dashboard_type
      if dashboard_type == "user"
        render "dashboard_user"
        return
      end
      if dashboard_type == "board"
        render "dashboard_board"
        return
      end
    end

    #render "dashboard_user"
  end

  #Finds publications created by current user and are part of the default community or not assigned toa community.
  def user_dashboard
    #@publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    #assuming 4 find calls faster than the above, then splits
    communities = []
    default_community = Community.default
    unless default_community.nil? 
      communities << default_community.id.to_s
    end
    communities << nil

    # TODO  we need a better way to trigger site-specific functionality
    is_perseids = SiteHelper::is_perseids?

    # for Perseids we want to show community info on the main dashboard
    show_comm = is_perseids ?  {} : { :community_id => communities }

    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }.merge(show_comm), :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }.merge(show_comm), :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }.merge(show_comm), :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }.merge(show_comm), :include => [{:identifiers => :votes}], :order => "updated_at DESC")

    if is_perseids
      @finalizing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :owner_id => @current_user.id, :status => 'finalizing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @assigned_publications = Assignment.find_all_by_user_id(@current_user.id, :conditions => {:vote_id => nil }, :order => "updated_at DESC").collect{|a|a.publication}
    end

    # TODO enable more fine grained control of events that are shown
    if (@current_user.admin || @current_user.developer || ! is_perseids)    
      @show_events = true
    end
    if is_perseids
      render "user_dashboard_perseids"
    else
      render "user_dashboard"
    end
  end

  #Finds publications created by the current user and are part of the specified community.
  def user_community_dashboard
    is_perseids = SiteHelper::is_perseids?
    cid = params[:community_id]
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    if is_perseids
      @finalizing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :owner_id => @current_user.id, :status => 'finalizing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @assigned_publications = Assignment.find_all_by_user_id(@current_user.id, :conditions => {:vote_id => nil }, :order => "updated_at DESC").select{|a| a.publication.community_id && a.publication.community_id == cid.to_i}.collect{|a|a.publication}
   end

    @community = Community.find_by_id(cid)
    if is_perseids
      render "user_dashboard_perseids"
    else
      render "user_dashboard"
    end
  end

  def export_options

    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

  end

  def export_publication_package

  end



  #Shows all publications for the current user (excepting archived status).
  def user_complete_dashboard
 #   @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => { :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
 #   @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
 #   @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
 #   @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
 #   @finalizing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :owner_id => @current_user.id,  :status => 'finalizing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")


    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => { :owner_type => 'User', :owner_id => @current_user.id, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :owner_id => @current_user.id, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :owner_id => @current_user.id, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :owner_id => @current_user.id, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @finalizing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :owner_id => @current_user.id, :status => 'finalizing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")



    if SiteHelper::is_perseids?
      render "user_dashboard_perseids"
    else
      render "user_dashboard"
    end
  end

  #Shows dashboard for the current user's board using the specified board_id.
  def board_dashboard
    find_board_publications(params[:board_id], params[:offset], 50)
    @current_board = @board
    if SiteHelper::is_perseids?
      render "board_dashboard_perseids"
    else
      render "board_dashboard"
    end
  end

  def archives
   # @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :status => 'archived', :parent_id => nil }, :include => :identifiers, :order => "updated_at DESC")
    #@board_final_pubs = Array.new()
    #@events = Array.new()
    if params[:board_id]
      @board = Board.find_by_id(params[:board_id])
      @publications = @board.publications.find( :all, :conditions => { :status => 'archived' }, :include => :identifiers, :order => "updated_at DESC")
    else
      @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :status => 'archived', :parent_id => nil }, :include => :identifiers, :order => "updated_at DESC")
    end
    unless @publications.size > 0
      flash[:notice] = "You have no archived publications!"
      if params[:board_id]
        redirect_to :controller => "user", :action => "board_dashboard", :board_id => params[:board_id]
      else
        redirect_to dashboard_url
      end
    end
    SiteHelper::is_perseids? ? render 'archives_perseids' : 'archives'
  end

  def update_terms
    #only let current user change this data
    if @current_user.id != params[:id].to_i()
      flash[:warning] = "Invalid Access."

      redirect_to ( dashboard_url ) 
      return
    end
    
    @user = User.find(params[:id])

    if (params[:accept])
      terms = {:accepted_terms => Sosol::Application.config.current_terms_version}
      begin 
        @user.update_attributes(terms)
        flash[:notice] = 'Thank you for accepting the terms of service'
        if !session[:entry_url].blank?
          redirect_to session[:entry_url]
          session[:entry_url] = nil
          return
        else
          redirect_to :controller => "user", :action => "dashboard"
          return
        end
        redirect_to dashboard_url
      rescue Exception => e
        flash[:error] = 'Error occured - user was not updated.'
        redirect_to :controller => "user", :action => "terms"
      end
    else
      flash[:warning] = 'You must accept the terms of service to continue'
      redirect_to :controller => "user", :action => "terms"
    end
  end
  
  def update_personal
    #only let current user change this data
    if @current_user.id != params[:id].to_i()
      flash[:warning] = "Invalid Access."

      redirect_to ( dashboard_url ) #just send them back to their own dashboard...side effects here?
      return
    end

    @user = User.find(params[:id])

    begin
      @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :controller => "user", :action => "account"
    rescue Exception => e
      flash[:error] = 'Error occured - user was not updated.'
      redirect_to :controller => "user", :action => "account"
    end
  end

  def current_user_is_master_admin?
    if !@current_user.is_master_admin
      flash[:warning] = "Invalid Access."
      redirect_to ( dashboard_url ) #just send them back to their own dashboard...side effects here?
      return false
    end

    return true
  end


=begin
Admin Settings allow certain rights to these groups.


Master Admin:
  Can set all user admin rights

Community Master Admin:
  they can create destroy communities, pick community admins

Community Admins:
  (note these are set on the commuity page not via user admins)
  can edit their communities

Admin:
  Setup etc. boards
  Can email all users

Developer:
  Extra views with debugging info.

=end



  #Admin Settings allow certain rights to these groups.
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
    #shows whatever they have the right to administer

  end

   #Admin route which lists users sorted by email address
   #Accessible to master admin only
   #*Returns*
   #- list of all users
   #- redirects to dashboard if user isn't master admin
   def index_users_by_email
    if current_user_is_master_admin?
      @users = User.find(:all, :order => 'email')
    end
   end

   #Admin route to confirm delete of a user account
   #Accessible to master admin only
   #*Returns*
   #- list of publications for selected user account 
   #- redirects to dashboard if user isn't master admin
   #- or if user for deletion is the same as the current user
   def confirm_delete
    if current_user_is_master_admin? 
      @user = User.find_by_id(params[:user_id])
      if @user == @current_user
        flash[:error] = "You cannot delete yourself"
        redirect_to dashboard_url and return
      end
      @publications = []
      @publications.concat(Publication.find_all_by_owner_id(@user.id, :conditions => {:owner_type => 'User', :creator_id => @user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC"))
      @publications.concat(Publication.find_all_by_owner_id(@user.id, :conditions => {:owner_type => 'User', :creator_id => @user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC"))
      @publications.concat(Publication.find_all_by_owner_id(@user.id, :conditions => {:owner_type => 'User', :creator_id => @user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC"))
      if (@publications.length > 0) 
        flash[:warning] = "This user has pending publications which will be destroyed.  Consider downloading a backup first."
      end
    end
   end

   #Admin route to delete a user
   #Accessible to master admin only
   #*Returns*
   # -redirects to dashboard after deletion
   def delete
    if current_user_is_master_admin?
      @user = User.find_by_id(params[:user_id])
      if @user == @current_user
        flash[:error] = "You cannot delete yourself"
        redirect_to dashboard_url and return
      end
      username = @user.name
      begin 
        @user.destroy
        flash[:notice] = "Deleted User #{username}"
      rescue Exception => e
        flash[:error] = "Error deleting user #{username}"
        Rails.logger.error(e.backtrace)
      end
      redirect_to dashboard_url
    end
   end

   def index_user_admins
    if current_user_is_master_admin?
      @users = User.find(:all)
    end
   end

   def edit_user_admins
     if current_user_is_master_admin?
      @user = User.find_by_id(params[:user_id])
    else
      flash[:warning] = "You do not have permission to edit user admins."
      redirect_to dashboard_url
     end

   end


  def update_admins
    if current_user_is_master_admin?
      @user = User.find(params[:id])

      begin
        @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        redirect_to :controller => "user", :action => "index_user_admins"
      rescue Exception => e
        flash[:error] = 'Error occured - user was not updated.'
        redirect_to :controller => "user", :action => "index_user_admins"
      end
    end


  end



  def create_email_everybody
    if !@current_user.admin
      flash[:error] = "Only Admin Users can send an email to all SoSOL users."
      redirect_to dashboard_url
      return
    end

  end

  def email_everybody
    if !@current_user.admin
      flash[:error] = "Only Admin Users can create an email to all SoSOL users."
      redirect_to dashboard_url
      return
    end
    if params[:email_subject].gsub(/^\s+|\s+$/, '') == "" || params[:email_content].gsub(/^\s+|\s+$/, '') == ""
      flash[:notice] = 'Email subject and content are both required.'
      #redirect_to :controller => "user", :action => "create_email_everybody"
      redirect_to sendmsg_url
      return
    end

    User.compose_email(params[:email_subject], params[:email_content])

    flash[:notice] = 'Email to all users was successfully sent.'
    redirect_to dashboard_url
  end

  def download_board_publications
    find_board_publications(params[:board_id], "0", -1)
    require 'zip/zip'
    require 'zip/zipfilesystem'
    t = Tempfile.new("board_download_#{@board.name}_#{@current_user.name}-#{request.remote_ip}")
    Zip::ZipOutputStream.open(t.path) do |zos|
        @finalizing_publications.each do |publication|
          publication.identifiers.each do |id|
            zos.put_next_entry( File.join(["finalizing",id.to_path] ))
            zos << id.xml_content
          end
        end
        @approved_publications.each do |publication|
          publication.identifiers.each do |id|
            zos.put_next_entry( File.join(["approved",id.to_path] ))
            zos << id.xml_content
          end
        end
        @board_voting_publications.each do |publication|
          publication.identifiers.each do |id|
            zos.put_next_entry( File.join(["reviewing",id.to_path] ))
            zos << id.xml_content
          end
        end
      
    end
    filename = "board_download_#{@board.name}_#{@current_user.name}_" + Time.now.to_s + ".zip"

    send_data File.read(t.path), :type => 'application/zip', :filename => filename
    t.close
    t.unlink
  end

  # download all publications to for the specified user_id
  # admin action
  def download_all_user_publications
    if current_user_is_master_admin?
      @user = User.find_by_id(params[:user_id])
      require 'zip/zip'
      require 'zip/zipfilesystem'
      @submitted_publications = Publication.find_all_by_owner_id(@user.id, :conditions => {:owner_type => 'User', :creator_id => @user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @editing_publications = Publication.find_all_by_owner_id(@user.id, :conditions => {:owner_type => 'User', :creator_id => @user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @new_publications = Publication.find_all_by_owner_id(@user.id, :conditions => {:owner_type => 'User', :creator_id => @user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @publications = @submitted_publications + @editing_publications  + @new_publications 
      t = Tempfile.new("publication_download_#{@user.name}-#{request.remote_ip}")

      Zip::ZipOutputStream.open(t.path) do |zos|
        @publications.each do |publication|
          publication.identifiers.each do |id|
            #full path as used in repo
            zos.put_next_entry( id.to_path)
            zos << id.xml_content
          end
        end
      end
      filename = "publication_download_#{@user.name}_" + Time.now.to_s + ".zip"
      send_data File.read(t.path), :type => 'application/zip', :filename => filename
      t.close
      t.unlink
    end
  end

  #Combines all of the user's publications (for PE or the given board, regardless of status) into one download.
  def download_user_publications

    require 'zip/zip'
    require 'zip/zipfilesystem'


    cid = params[:community_id]
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

    @community = Community.find_by_id(cid)

    @publications = @submitted_publications + @editing_publications  + @new_publications + @committed_publications
    t = Tempfile.new("publication_download_#{@current_user.name}-#{request.remote_ip}")

    Zip::ZipOutputStream.open(t.path) do |zos|
        @publications.each do |publication|
          publication.identifiers.each do |id|
            #full path as used in repo
            zos.put_next_entry( id.to_path)
            zos << id.xml_content
          end
        end
    end

    # End of the block  automatically closes the zip? file.

    # The temp file will be deleted some time...
      community = "PE"
    if @community
      community = @community.format_name
    end
    filename = @current_user.name + "_" + community + "_" + Time.now.to_s + ".zip"
    send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => filename

    t.close
  end

  #Determines which combos of boards & publication status' exist so we can ask the user which one they want to download.
  def download_options

    #has become overkill for current method, really only need to see if any of these publications exists, dont need the whole list
    cid = nil
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

   # @community = Community.find_by_id(cid)

    @communities = Hash.new
    if @current_user.community_memberships && @current_user.community_memberships.length > 0
        @current_user.community_memberships.each do |community|
          #raise community.id.to_s
          cid = community.id
          #raise community.name
          @communities[cid] = Hash.new
          @communities[cid][:id] = cid
          @communities[cid][:name] = community.format_name
          @communities[cid][:submitted_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
          @communities[cid][:editing_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
          @communities[cid][:new_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
          @communities[cid][:committed_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
        end
    end


  end

  #Collects and downloads zip file with all of the publications of the given status and community (or PE if no community).
  def download_by_status

    require 'zip/zip'
    require 'zip/zipfilesystem'

    status_wanted = params[:status] || "unknown" #"committed"
    #only let them download status that are accessable
    if ! %w{new editing submitted committed}.include?status_wanted
      #status_wanted = "committed"
      flash[:error] = status_wanted + " status is not downloadable."
      redirect_to dashboard_url
      return
    end

    cid = params[:community_id] || nil
    if cid
      @community = Community.find_by_id(cid)
    end

    @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => status_wanted }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

    t = Tempfile.new("publication_download_#{@current_user.name}-#{request.remote_ip}")

    Zip::ZipOutputStream.open(t.path) do |zos|
        @publications.each do |publication|
          publication.identifiers.each do |id|
            #raise id.title + " ... " + id.name + " ... " + id.title.gsub(/\s/,'_')

            #simple paths for just this pub
            #zos.put_next_entry( id.class::FRIENDLY_NAME + "-" + id.title.gsub(/\s/,'_') + ".xml")

            #full path as used in repo
            zos.put_next_entry( id.to_path)

            zos << id.xml_content
          end
        end
    end

    # End of the block  automatically closes the zip? file.

    # The temp file will be deleted some time...
  #add com name
    community = "PE"
    if @community
      community = @community.format_name
    end
    filename = @current_user.name + "_" + community +  "_" + status_wanted + "_" + Time.now.to_s + ".zip"
    send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => filename

    t.close
  end

  #Combines all of the user's publications (for PE or the given board, regardless of status) into one download.
  def download_user_publications

    require 'zip/zip'
    require 'zip/zipfilesystem'


    cid = params[:community_id]
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

    @community = Community.find_by_id(cid)

    @publications = @submitted_publications + @editing_publications  + @new_publications + @committed_publications
    t = Tempfile.new("publication_download_#{@current_user.name}-#{request.remote_ip}")

    Zip::ZipOutputStream.open(t.path) do |zos|
        @publications.each do |publication|
          publication.identifiers.each do |id|
            #full path as used in repo
            zos.put_next_entry( id.to_path)
            zos << id.xml_content
          end
        end
    end

    # End of the block  automatically closes the zip? file.

    # The temp file will be deleted some time...
      community = "PE"
    if @community
      community = @community.format_name
    end
    filename = @current_user.name + "_" + community + "_" + Time.now.to_s + ".zip"
    send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => filename

    t.close
  end

  #Determines which combos of boards & publication status' exist so we can ask the user which one they want to download.
  def download_options

    #has become overkill for current method, really only need to see if any of these publications exists, dont need the whole list
    cid = nil
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")

   # @community = Community.find_by_id(cid)

    @communities = Hash.new
    if @current_user.community_memberships && @current_user.community_memberships.length > 0
        @current_user.community_memberships.each do |community|
          #raise community.id.to_s
          cid = community.id
          #raise community.name
          @communities[cid] = Hash.new
          @communities[cid][:id] = cid
          @communities[cid][:name] = community.format_name
          @communities[cid][:submitted_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
          @communities[cid][:editing_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
          @communities[cid][:new_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
          @communities[cid][:committed_publications] = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
        end
    end


  end

  protected
    # Gathers board publications for display
    # *Args*:
    #  - +board_id+ id of the board
    #  - +offset+ offset index for pagination
    #  - +max_voting+ max count of voting pubs to return
    # Sets up view variables:
    #  @board, @board_final_pubs, @finalizing_publications, @approved_publications,
    #  @offset, @count, @board_voting_publications, @needs_reviewing_publications
    #  @member_already_voted_on
    def find_board_publications(board_id, offset, max_voting=50)
      @board = Board.find_by_id(board_id)
      show_all = ! @board.community_id || ! @board.requires_assignment || @board.community.admins.include?(@current_user) 

      #get publications for the member to finalize
      @board_final_pubs = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :status => 'finalizing'}, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @finalizing_publications =  @board_final_pubs.collect{|p| ((! p.parent.nil? && p.parent.owner == @board)) ? p : nil}.compact

      #get publications that have been approved
      #@approved_publications = @board.publications.collect{|p| p.status == "approved" ? p :nil}.compact
      if show_all
        @approved_publications = Publication.find_all_by_owner_id(@board.id, :conditions => {:owner_type => "Board", :status => "approved" }, :include => [{:identifiers => :votes}], :order => "updated_at DESC"  )
      else
        @approved_publications = []
      end

      #remove approved publications if in the finalizer list
      @finalizing_publications.each do |fp|
        #remove it from the list of approved publications
        #unless the user can reassign it
        @approved_publications.each do |ap|
         if fp.origin == ap.origin && ! ap.user_can_assign?(@current_user)
           @approved_publications.delete(ap)
         end
        end
      end

      # biblio voting stacked up and created huge problems (e.g. running out of heap), so
      # we now paginate voting items 50 at a time.
      if offset
        @offset = Integer(offset)
      else
        @offset = 0
      end
      @count = Publication.count(:conditions => {:owner_id => @board.id, :owner_type => 'Board', :status => "voting"})

      if max_voting > 0
        limit = max_voting
      else 
        limit = @count
      end

      #find all pubs that are still in voting phase
      @board_voting_publications = Publication.find(:all, :conditions => {:owner_id => @board.id, :owner_type => 'Board', :status => "voting"}, :include => [{:identifiers => :votes}], :order => "updated_at DESC", :limit => limit, :offset => @offset )
      #find all pubs that the user needs to review
      # and is assigned to review, if applicable
      @needs_reviewing_publications = @board_voting_publications.collect{ |p|
        needs_review = false
        if ! p.is_assignable? || # if the publication can't be assigned, then anyone can review it
          p.assignments.select{ |a| a.user_id == @current_user.id }.size == 1 || # assigned members can vote
          p.user_can_assign?(@current_user) # admins can vote or assign
          p.identifiers.each do |id|
            if id.needs_reviewing?(@current_user.id)
              needs_review = true
            end
          end
          needs_review ? p :nil
        end
      }.compact
      if show_all
        if @needs_reviewing_publications.nil?
          @member_already_voted_on = @board_voting_publications
        else
          @member_already_voted_on = @board_voting_publications - @needs_reviewing_publications
        end
      end

      # move publications with votes to the front of the array
      voted_indices = @needs_reviewing_publications.to_enum(:each_index).select {|i| @needs_reviewing_publications[i].votes.length > 0}
      voted_indices.each {|index| @needs_reviewing_publications.unshift(@needs_reviewing_publications.delete_at(index))}

    end

end
