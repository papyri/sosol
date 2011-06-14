class UserController < ApplicationController
  layout 'site'
  before_filter :authorize, :except => [:signin, :signout]
  
  def signout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
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
      render "usage_stats"
      return
    end
    redirect_to dashboard_url
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
    #below selects publications to show in standard user data section of dashboard
    #@publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => "owner_type = 'User' AND owner_id = creator_id AND parent_id is null", :include => :identifiers)
    
    unless fragment_exist?(:action => 'dashboard', :part => "your_publications_#{@current_user.id}")
      @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil }, :include => [{:identifiers => :votes}], :order => "updated_at DESC")
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
  
   def index_user_admins
    if current_user_is_master_admin?
      @users = User.find(:all)
    end
   end
   
   def edit_user_admins
     if current_user_is_master_admin?
      @user = User.find_by_id(params[:user_id])
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
  
  

end
