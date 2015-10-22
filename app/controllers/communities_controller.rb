class CommunitiesController < ApplicationController

  before_filter :authorize
  
  # GET /communities
  # GET /communities.xml
  def index
    @communities = Community.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @communities }
    end
  end

  # GET /communities/1
  # GET /communities/1.xml
  def show
    @community = Community.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @community }
    end
  end

  # GET /communities/new
  # GET /communities/new.xml
  def new

  end

  # GET /communities/1/edit
  def edit
    @community = Community.find(params[:id].to_s)
  end

  # POST /communities
  # POST /communities.xml
  def create
    @community = Community.new(params[:community])
    @community.admins << @current_user

    respond_to do |format|
      if @community.save!
        flash[:notice] = 'Community was successfully created.'
        format.html { redirect_to(:action => 'edit', :id => @community.id) }
        format.xml  { render :xml => @community, :status => :created, :location => @community }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /communities/1
  # PUT /communities/1.xml
  def update
    @community = Community.find(params[:id].to_s)

    respond_to do |format|
      if @community.update_attributes(params[:community])
        flash[:notice] = 'Community was successfully updated.'
        format.html { redirect_to(:action => 'edit', :id => @community.id) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /communities/1
  # DELETE /communities/1.xml
  def destroy
    @community = Community.find(params[:id].to_s)
    community_name = @community.format_name
    
    #find all of the publications that belonged to the community and reset them to sosol
    @community.publications.each do |p|
      p.community = nil
      p.save
    end
    #this will not affect the boards copies & they will be deleted along with the community
    @community.destroy

    respond_to do |format|
      flash[:notice] = community_name + ' community no longer exist.'
      format.html { redirect_to(:controller=>'user', :action => 'admin') }
      format.xml  { head :ok }
    end
  end
  
  #List all the publications that belong to a community. (hidden view as of 10-10-2011)
  # GET /communities
  def list_publications
    begin
      @community = Community.find(params[:id].to_s)
    rescue
      @community = nil
      return
    end
     @publications = Publication.find_all_by_community_id(@community.id, :include => [:identifiers], :order => "updated_at DESC")
  end

  # GET /communities/1/add_member_page
  def add_member_page
    @community = Community.find(params[:id].to_s)  
  end

  #Adds a member to the community members list. These are the users who can submit to the community.
  # GET /communities/1/add_member?user_id=1
  def add_member    
    @community = Community.find(params[:id].to_s)
    @community.add_member(params[:user_id])
    redirect_to :action => "add_member_page", :id => @community.id
  end

  #Removes member from the communities members list.
  # GET /communities/1/remove_member?user_id=1
  def remove_member
    user = User.find(params[:member_id].to_s)

    @community = Community.find(params[:id].to_s)
    
    @community.members.delete(user)
    @community.save

    #redirect_to :action => "edit", :id => (@community).id
    redirect_to :action => "add_member_page", :id => @community.id
  end

  #Removes the current user from the community members list. Used to let the user leave a community.
  def remove_current_user_membership
    @community = Community.find(params[:id].to_s)
    # but users shouldn't be allowed to leave the default community
    if @community.is_default?
      flash[:notice] = "You cannot leave the default community."
    else
      @community.members.delete(@current_user)
      @community.save
    end
    redirect_to :controller => "user", :action => "admin"    
  end

  def add_admin_page
    @community = Community.find(params[:id].to_s)
  end

  #Adds user to community admin list.
  def add_admin
   # raise params.inspect
    @community = Community.find(params[:id].to_s)
    user = User.find_by_id(params[:user_id].to_s)

    #raise @community.admins.length.to_s

    if nil == @community.admins.find_by_id(user.id) 
    
      @community.admins << user
      @community.save
    end

    redirect_to :action => "add_admin_page", :id => @community.id
  end

  #Removes user form community admin list.
  def remove_admin
    user = User.find(params[:admin_id].to_s)
    @community = Community.find(params[:id].to_s)

    if user == @current_user
      #warn them about deleting themselves as admins
      render "current_user_warning"
      return
      if 1 == @community.admins.length
        #dont let them remove themselves if they are the last admin
        flash[:error] = "Cannot remove you since you are the only admin for this community."
        redirect_to :action => "add_admin_page",:id => @community.id
        return
      end
    end

    @community.admins.delete(user)
    @community.save

    redirect_to :action => "add_admin_page", :id => @community.id
  end

  #Removes the current user from the community admin list.
  def remove_current_user  
    @community = Community.find(params[:id].to_s)

    @community.admins.delete(@current_user)
    @community.save

    redirect_to :action => "show", :id => @community.id
  end


  # GET /communities/1/confirm_destroy
  def confirm_destroy
      @community = Community.find(params[:id].to_s)
  end

  # GET /communities/1/select_default
  def select_default
    @communities = Community.where(["is_default = ?", false ])
  end

  # POST /communities/1/change_default?new_default=2
  def change_default
    @new_default = Community.find(params[:new_default].to_s)
    if (@new_default.nil?)
      flash[:error] = "You must select a valid community."
      redirect_to :action => "select_default" and return
    end
    flash[:notice] = "Default community changed to #{@new_default.friendly_name}"
    Community.change_default(@new_default)
    redirect_to :action => "index" and return
  end

  # filter to enforce system level admin access for an action
  def enforce_admin
    unless @current_user.admin
      flash[:error] = "This action requires administrator rights"
      redirect_to :action => "index" and return
    end
  end

  # filter to enforce at least community level admin access for an action
  def enforce_community_admin
    @community = Community.find(params[:id].to_s)
    unless (@community.admins.include? @current_user) || @current_user.admin
      flash[:error] = "This action requires community administrator rights"
      redirect_to :action => "index" and return
    end   
  end
end
