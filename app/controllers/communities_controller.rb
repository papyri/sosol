class CommunitiesController < ApplicationController
  before_action :authorize

  # GET /communities
  # GET /communities.xml
  def index
    @communities = Community.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @communities }
    end
  end

  # GET /communities/1
  # GET /communities/1.xml
  def show
    @community = Community.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @community }
    end
  end

  # GET /communities/new
  # GET /communities/new.xml
  def new
    @community = Community.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @community }
    end
  end

  # GET /communities/1/edit
  def edit
    @community = Community.find(params[:id].to_s)
  end

  # POST /communities
  # POST /communities.xml
  def create
    @community = Community.new(community_params)
    @community.transaction do
      @community.save!
      @community.admins << @current_user

      respond_to do |format|
        if @community.save!
          flash[:notice] = 'Community was successfully created.'
          format.html { redirect_to(action: 'edit', id: @community.id) }
          format.xml  { render xml: @community, status: :created, location: @community }
        else
          format.html { render action: 'new' }
          format.xml  { render xml: @community.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /communities/1
  # PUT /communities/1.xml
  def update
    @community = Community.find(params[:id].to_s)

    respond_to do |format|
      if params[:community].present? && @community.update(community_params)
        flash[:notice] = 'Community was successfully updated.'
        format.html { redirect_to(action: 'edit', id: @community.id) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /communities/1
  # DELETE /communities/1.xml
  def destroy
    @community = Community.find(params[:id].to_s)
    community_name = @community.format_name

    # find all of the publications that belonged to the community and reset them to sosol
    @community.publications.each do |p|
      p.community = nil
      p.save
    end
    # this will not affect the boards copies & they will be deleted along with the community
    @community.destroy

    respond_to do |format|
      flash[:notice] = "#{community_name} community no longer exist."
      format.html { redirect_to(controller: 'user', action: 'admin') }
      format.xml  { head :ok }
    end
  end

  # List all the publications that belong to a community. (hidden view as of 10-10-2011)
  def list_publications
    begin
      @community = Community.find(params[:id].to_s)
    rescue StandardError
      @community = nil
      return
    end
    @publications = Publication.where(community_id: @community.id).includes(:identifiers).order(updated_at: :desc)
  end

  def add_member_page
    @community = Community.find(params[:id].to_s)
  end

  # Adds a member to the community members list. These are the users who can submit to the community.
  def add_member
    @community = Community.find(params[:id].to_s)
    user = User.find_by(id: params[:user_id].to_s)

    if @community.members.find_by(id: user.id).nil?
      @community.members << user
      @community.save
    end

    redirect_to action: 'add_member_page', id: @community.id
  end

  # Removes member from the communities members list.
  def remove_member
    user = User.find(params[:member_id].to_s)

    @community = Community.find(params[:id].to_s)

    @community.members.delete(user)
    @community.save

    # redirect_to :action => "edit", :id => (@community).id
    redirect_to action: 'add_member_page', id: @community.id
  end

  # Removes the current user from the community members list. Used to let the user leave a community.
  def remove_current_user_membership
    @community = Community.find(params[:id].to_s)

    @community.members.delete(@current_user)
    @community.save

    # redirect_to :action => "edit", :id => (@community).id
    redirect_to controller: 'user', action: 'admin'
  end

  def add_admin_page
    @community = Community.find(params[:id].to_s)
  end

  # Adds user to community admin list.
  def add_admin
    # raise params.inspect
    @community = Community.find(params[:id].to_s)
    user = User.find_by(id: params[:user_id].to_s)

    # raise @community.admins.length.to_s

    if @community.admins.find_by(id: user.id).nil?

      @community.admins << user
      @community.save
    end

    redirect_to action: 'add_admin_page', id: @community.id
  end

  # Removes user form community admin list.
  def remove_admin
    user = User.find(params[:admin_id].to_s)
    @community = Community.find(params[:id].to_s)

    if user == @current_user
      # warn them about deleting themselves as admins
      render 'current_user_warning'
      return
      if @community.admins.length == 1
        # dont let them remove themselves if they are the last admin
        flash[:error] = 'Cannot remove you since you are the only admin for this community.'
        redirect_to action: 'add_admin_page', id: @community.id
        return
      end
    end

    @community.admins.delete(user)
    @community.save

    redirect_to action: 'add_admin_page', id: @community.id
  end

  # Removes the current user from the community admin list.
  def remove_current_user
    @community = Community.find(params[:id].to_s)

    @community.admins.delete(@current_user)
    @community.save

    redirect_to action: 'show', id: @community.id
  end

  def edit_end_user
    @community = Community.find(params[:id].to_s)
  end

  # Sets the end_user for the community.
  # If this is not set, then publications may not be submitted nor finalized.
  def set_end_user
    @community = Community.find(params[:id].to_s)
    user = User.find_by(id: params[:user_id].to_s)

    @community.end_user_id = user.id
    @community.save

    redirect_to action: 'edit', id: @community.id
  end

  def confirm_destroy
    @community = Community.find(params[:id].to_s)
  end

  private

  def community_params
    params.require(:community).permit(:name, :friendly_name, :description, :admins)
  end
end
