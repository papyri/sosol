class EndUserCommunitiesController < CommunitiesController

  before_filter :authorize
  # anybody can create a new end user community but only community 
  # admins can edit one
  before_filter :enforce_community_admin, :except => [:index, :new, :create, :remove_current_user_membership]

  # GET /end_user_communities
  # GET /end_user_communities.json
  def index
    @communities = EndUserCommunity.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @communities }
      format.json { render json: @communities }
    end
  end

  # GET /end_user_communities/new.json
  def new
    @community = EndUserCommunity.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @community }
    end
  end

  # GET /end_user_communities/1/edit
  def edit
    @community = EndUserCommunity.find(params[:id])
  end

  # POST /end_user_communities
  # POST /end_user_communities.json
  def create
    @community = EndUserCommunity.new(params[:end_user_community])
    @community.admins << @current_user

    respond_to do |format|
      if @community.save
        flash[:notice] = 'EndUser community was successfully created.'
        format.html { redirect_to(:action => 'edit', :id => @community.id) }
        format.json { render json: @community, status: :created, location: @community }
      else
        format.html { render action: "new" }
        format.json { render json: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /end_user_communities/1
  # PUT /end_userr_communities/1.json
  def update
    @community = EndUserCommunity.find(params[:id])

    respond_to do |format|
      if @community.update_attributes(params[:end_user_community])
        flash[:notice] = 'EndUser community was successfully updated.'
        format.html { redirect_to(:action => 'edit', :id => @community.id) }
        format.xml  { head :ok }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @community.errors, status: :unprocessable_entity }
        format.json { render json: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit_end_user
    @community = Community.find(params[:id].to_s)
  end
  
  #Sets the end_user for the community. 
  #If this is not set, then publications may not be submitted nor finalized.
  def set_end_user
    @community = Community.find(params[:id].to_s)
    user = User.find_by_id(params[:user_id].to_s)
    
    @community.end_user_id = user.id
    @community.save
    
    redirect_to :action => "edit", :id => @community.id
  end

end
