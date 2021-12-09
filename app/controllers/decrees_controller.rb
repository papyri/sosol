class DecreesController < ApplicationController
  
  #layout "site"
  before_action :authorize
  
  # GET /decrees
  # GET /decrees.xml
  def index
    @decrees = Decree.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @decrees }
    end
  end

  # GET /decrees/1
  # GET /decrees/1.xml
  def show
    @decree = Decree.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @decree }
    end
  end

  # GET /decrees/new
  # GET /decrees/new.xml
  def new
    @decree = Decree.new
    @decree.board_id = params[:board_id].to_s
    @board = Board.find(params[:board_id].to_s)
   

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @decree }
    end
  end

  # GET /decrees/1/edit
  def edit
    @decree = Decree.find(params[:id].to_s)
  end

  # POST /decrees
  # POST /decrees.xml
  def create
    @decree = Decree.new(decree_params)

    if @decree.save
      board = Board.find(@decree.board_id)
      board.decrees << @decree
      board.save
      
      flash[:notice] = 'Decree was successfully created.'
      redirect_to :controller => "boards", :action => "edit", :id => @decree.board_id
    end

#    respond_to do |format|
#      if @decree.save
#        flash[:notice] = 'Decree was successfully created.'
#        format.html { redirect_to(@decree) }
#        format.xml  { render :xml => @decree, :status => :created, :location => @decree }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @decree.errors, :status => :unprocessable_entity }
#      end
#    end
    
  end

  # PUT /decrees/1
  # PUT /decrees/1.xml
  def update
    @decree = Decree.find(params[:id].to_s)

    respond_to do |format|
      if params[:decree].present? && @decree.update(decree_params)
        flash[:notice] = 'Decree was successfully updated.'
        
        format.html { redirect_to :controller => "boards", :action => "edit", :id => @decree.board_id }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @decree.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /decrees/1
  # DELETE /decrees/1.xml
  def destroy
    @decree = Decree.find(params[:id].to_s)
    @decree.destroy

    respond_to do |format|
      format.html { redirect_to :controller => "boards", :action => "edit", :id => @decree.board_id }
      #format.html { redirect_to(decrees_url) }
      format.xml  { head :ok }
    end
  end

  private

    def decree_params
      params.require(:decree).permit(:association,:tally_method,:action,:trigger,:choices,:board_id)
    end
end
