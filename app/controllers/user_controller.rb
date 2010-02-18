class UserController < ApplicationController
  layout 'site'
  
  def signout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
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
    @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :parent_id => nil }, :include => :identifiers, :order => "updated_at DESC")
    #below selects publications current user is responsible for finalizing to show in board section of dashboard
    #@board_final_pubs = Publication.find_all_by_owner_id(@current_user.id, :conditions => "owner_type = 'User' AND status = 'finalizing'", :include => :identifiers, :order => "updated_at DESC")
    @board_final_pubs = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :status => 'finalizing'}, :include => :identifiers, :order => "updated_at DESC")
       
    @boards = @current_user.boards   
    #or do we want to use the creator id?
    #@publications = Publication.find_all_by_creator_id(@current_user.id, :include => :identifiers)
    
    @events = Event.find(:all, :order => "created_at DESC",
                         :include => [:owner, :target])[0..25]
    
  end
  
  def archives
   # @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :status => 'archived', :parent_id => nil }, :include => :identifiers, :order => "updated_at DESC")
    #@board_final_pubs = Array.new()
    #@events = Array.new()
    puts  params[:board_id]
    if params[:board_id] 
      @board = Board.find_by_id(params[:board_id])
      puts "==================="
      @publications = @board.publications.find( :all, :conditions => { :status => 'archived' }, :include => :identifiers, :order => "updated_at DESC")
    else
      @publications = Publication.find_all_by_owner_id(@current_user.id, :conditions => {:owner_type => 'User', :creator_id => @current_user.id, :status => 'archived', :parent_id => nil }, :include => :identifiers, :order => "updated_at DESC")
    end
    

  end  

  def update_personal
  #TODO don't let any bozo change this data
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
  
  
end
