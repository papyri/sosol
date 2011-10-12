class CommunitiesController < ApplicationController
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
    @community = Community.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @community }
    end
  end

  # GET /communities/new
  # GET /communities/new.xml
  def new
    @community = Community.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @community }
    end
  end

  # GET /communities/1/edit
  def edit
    @community = Community.find(params[:id])
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
    @community = Community.find(params[:id])

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
    @community = Community.find(params[:id])
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



  def find_member

    @community = Community.find(params[:id])
    
  end
  
  def add_member_page
    @community = Community.find(params[:id])
    
  end

  def add_member
    
    @community = Community.find(params[:id])
    user = User.find_by_id(params[:user_id])


    if nil == @community.members.find_by_id(user.id) 
    
      @community.members << user
      @community.save
    end

    redirect_to :action => "add_member_page", :id => @community.id
  end

  def remove_member
    user = User.find(params[:member_id])

    @community = Community.find(params[:id])
    
    @community.members.delete(user)
    @community.save

    #redirect_to :action => "edit", :id => (@community).id
    redirect_to :action => "add_member_page", :id => @community.id
  end

  def remove_current_user_membership
    

    @community = Community.find(params[:id])
    
    @community.members.delete(@current_user)
    @community.save

    #redirect_to :action => "edit", :id => (@community).id
    redirect_to :controller => "user", :action => "admin"    
  end

  def add_admin_page
    @community = Community.find(params[:id])
    
  end

  def add_admin
   # raise params.inspect
    @community = Community.find(params[:id])
    user = User.find_by_id(params[:user_id])

    #raise @community.admins.length.to_s

    if nil == @community.admins.find_by_id(user.id) 
    
      @community.admins << user
      @community.save
    end

    redirect_to :action => "add_admin_page", :id => @community.id
  end

  def remove_admin
    
    user = User.find(params[:admin_id])

    @community = Community.find(params[:id])



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

  def remove_current_user  
    @community = Community.find(params[:id])

    @community.admins.delete(@current_user)
    @community.save

    redirect_to :action => "show", :id => @community.id
  end

  def edit_end_user
    @community = Community.find(params[:id])
  end
  
  def set_end_user
    @community = Community.find(params[:id])
    user = User.find_by_id(params[:user_id])
    
    @community.end_user_id = user.id
    @community.save
    
    redirect_to :action => "edit", :id => @community.id
  end
  
end
