class PassThroughCommunitiesController < CommunitiesController

  before_filter :authorize
  # anybody can create a new end user community but only community 
  # admins can edit one
  before_filter :enforce_community_admin, :except => [:index, :new, :create, :remove_current_user_membership]

  # GET /pass_through_communities
  # GET /pass_through_communities.json
  def index
    @communities = PassThroughCommunity.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @communities }
      format.json { render json: @communities }
    end
  end

  # GET /pass_through_communities/new.json
  def new
    @community = PassThroughCommunity.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @community }
    end
  end

  # GET /pass_through_communities/1/edit
  def edit
    @community = PassThroughCommunity.find(params[:id])
  end

  # POST /pass_through_communities
  # POST /pass_through_communities.json
  def create
    @community = PassThroughCommunity.new(params[:pass_through_community])
    @community.admins << @current_user

    respond_to do |format|
      if @community.save
        flash[:notice] = 'PassThrough community was successfully created.'
        format.html { redirect_to(:action => 'edit', :id => @community.id) }
        format.json { render json: @community, status: :created, location: @community }
      else
        format.html { render action: "new" }
        format.json { render json: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pass_through_communities/1
  # PUT /pass_throughr_communities/1.json
  def update
    @community = PassThroughCommunity.find(params[:id])

    respond_to do |format|
      if @community.update_attributes(params[:pass_through_community])
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


end
