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

    respond_to do |format|
      if @community.save
        format.html { redirect_to(@community, :notice => 'Community was successfully created.') }
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
        format.html { redirect_to(@community, :notice => 'Community was successfully updated.') }
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
    @community.destroy

    respond_to do |format|
      format.html { redirect_to(communities_url) }
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

    redirect_to :action => "edit", :id => (@community).id
  end

  def remove_member
    user = User.find(params[:member_id])

    @community = Community.find(params[:id])
    
    @community.members.delete(user)
    @community.save

    redirect_to :action => "edit", :id => (@community).id
  end


  def add_admin_page
    @community = Community.find(params[:id])
    
  end

  def add_admin
    
    @community = Community.find(params[:id])
    user = User.find_by_id(params[:user_id])

    if nil == @community.admins.find_by_id(user.id) 
    
      @community.admins << user
      @community.save
    end

    redirect_to :action => "edit", :id => (@community).id
  end

  def remove_admin
    user = User.find(params[:admin_id])

    @community = Community.find(params[:id])
    
    @community.admins.delete(user)
    @community.save

    redirect_to :action => "edit", :id => (@community).id
  end



end