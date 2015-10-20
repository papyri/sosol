class MasterCommunitiesController < CommunitiesController

  before_filter :authorize
  # only admins can create, edit or update master communitities
  # anybody can list or leave them
  before_filter :enforce_admin, :except => [ :index, :remove_current_membership ]

  # GET /master_communities
  # GET /master_communities.json
  def index
    @communities = MasterCommunity.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @communities }
      format.json { render json: @communities }
    end
  end

  # GET /master_communities/new.json
  def new
    @community = MasterCommunity.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @community }
    end
  end

  # GET /master_communities/1/edit
  def edit
    @community = MasterCommunity.find(params[:id])
  end

  # POST /master_communities
  # POST /master_communities.json
  def create
    @community = MasterCommunity.new(params[:master_community])
    @community.admins << @current_user

    respond_to do |format|
      if @community.save
        flash[:notice] = 'Master community was successfully created.'
        format.html { redirect_to(:action => 'edit', :id => @community.id) }
        format.json { render json: @community, status: :created, location: @community }
      else
        format.html { render action: "new" }
        format.json { render json: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /master_communities/1
  # PUT /master_communities/1.json
  def update
    @community = MasterCommunity.find(params[:id])

    respond_to do |format|
      if @community.update_attributes(params[:master_community])
        flash[:notice] = 'Master community was successfully updated.'
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

  def confirm_destroy
    @community = Community.find(params[:id].to_s)
    #TODO we want to prevent destroy of last master community - we need at least 1
  end

end
