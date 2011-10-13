class UserController < ApplicationController
  ##layout 'site'
  #layout 'header_footer'
  before_filter :authorize, :except => [:signin, :signout, :show, :info, :help]
  
  def signout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
  end
  
  def leave_community
    @community = Community.find(params[:com_id])
    
  end
  #default view of stats is only for the current user, see below for all users
  def usage_stats    
    @users = Array.new()
    @users << @current_user
  end

  #TODO who has the right to see this?, will this create any dangerous links to things that a user should not be able to do 
  def all_usage_stats
    if @current_user.admin || @current_user.developer
      @users = User.find(:all)
      
      #default to show last 2 weeks activity when showing all users
      @calc_date = Date.today - 14
      
      flash.now[:notice] = "Usage since #{@calc_date}"
      render "usage_stats"
      return
    end
    flash[:error] = "Only admins and developers are authorized to use this link."
    redirect_to dashboard_url
  end
  
  def all_users_links
    @users = User.find(:all, :order => "full_name ASC")
  end

  def info
    render :json => @current_user.nil? ? {} : @current_user
  end
  
  #view of stats for the user id page shown with optional date limitation
  def refresh_usage
    @users = [User.find_by_id(params[:save_user_id])]

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
        
    flash.now[:notice] = "Usage since #{@calc_date}"
    render "usage_stats"
  end
  
  #default view of stats for the user name entered/linked to
  def show
    @users = [User.find_by_name(params[:user_name])]
    if !@users.compact.empty?
      @calc_date = ''
      
      render "usage_stats"
      return
    else
      flash[:error] = "User not found."
      redirect_to dashboard_url
    end
  end
  
  def account
    if @current_user
      @identifiers = @current_user.user_identifiers
    end    
  end
  
  def signin
    
  end
  
  def developer
    if !@current_user.developer
      redirect_to dashboard_url
      return
    end
    @boards = Board.find(:all)
  end
  
#  def index      
#   if @current_user.admin
#     @users = User.find(:all)
#   else
#     render :file => 'public/403.html', :status => '403'
#   end
#  end
  
#  def ask_language_prefs
#    @langs = @current_user.language_prefs 
# end

#  def set_language_prefs
#    @current_user.language_prefs =  params[:languages]
#    @current_user.save
#    
#    redirect_to :controller => :user, :action => "dashboard"
#  end  
  
  def dashboard
    #don't let someone who isn't signed in go to the dashboard
    if @current_user == nil
      redirect_to :controller => "user", :action => "signin"
      return
    end
    
    unless params[:old]
    
      
      if params[:board_id]
        redirect_to :action => "board_dashboard", :board_id => params[:board_id]
        return
      else
        redirect_to :action => "user_dashboard"
        return
      end
      
    end
    
    
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
       
      @boards = @current_user.boards.ranked
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
      puts dashboard_type
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
  
  def user_dashboard
    
    #@publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    #assuming 4 find calls faster than the above, then splits
=begin
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
=end
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => nil, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => nil, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => nil, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => nil, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
        
    #render :layout => 'header_footer'
  end
  
  def user_community_dashboard
    cid = params[:community_id]
    @submitted_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid, :owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'submitted' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @editing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'editing' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @new_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'new' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    @committed_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:community_id => cid,:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil, :status => 'committed' }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
    
    @community = Community.find_by_id(cid)
    render "user_dashboard"
  end
  
  def board_dashboard
      @board = Board.find_by_id(params[:board_id])

      #get publications for the member to finalize
      @board_final_pubs = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :status => 'finalizing'}, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
      @finalizing_publications =  @board_final_pubs.collect{|p| ((p.parent.owner == @board)) ? p : nil}.compact
      
      #get publications that have been approved
      #@approved_publications = @board.publications.collect{|p| p.status == "approved" ? p :nil}.compact
      @approved_publications = Publication.find_all_by_owner_id(@board.id, :conditions => {:owner_type => "Board", :status => "approved" }, :include => [{:identifiers => :votes}], :order => "updated_at DESC"  )
    
      #remove approved publications if in the finalizer list
      @finalizing_publications.each do |fp|
        #remove it from the list of approved publications
        @approved_publications.each do |ap|
         if fp.origin == ap.origin
           @approved_publications.delete(ap)
         end
      
        end
     end





     #find all pubs that are still in voting phase 
     board_voting_publications = Publication.find_all_by_owner_id(@board.id, :conditions => {:owner_type => 'Board', :status => "voting"}, :include => [{:identifiers => :votes}], :order => "updated_at DESC"  )
     #find all pubs that the user needs to review
     @needs_reviewing_publications = board_voting_publications.collect{ |p|
        needs_review = false
        p.identifiers.each do |id|  
          if id.needs_reviewing?(@current_user.id)
            needs_review = true
          end
        end
        needs_review ? p :nil    
     }.compact
     
     if @needs_reviewing_publications.nil?
      @member_already_voted_on = board_voting_publications
    else
      @member_already_voted_on = board_voting_publications - @needs_reviewing_publications
      end
     
     #set so the correct tab will be active
     @current_board = @board
     #render :layout => 'header_footer'

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
  
  def admin
    #shows whatever they have the right to administer
    
    
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
      redirect_to create_email_everybody_path
      return
    end
    
    User.compose_email(params[:email_subject], params[:email_content])
    
    flash[:notice] = 'Email to all users was successfully sent.'
    redirect_to dashboard_url
  end
  
  

end
