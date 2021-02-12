class EmailersController < ApplicationController
  before_action :authorize
  
  def find_board_member
    @emailer = Emailer.find(params[:id].to_s)
  end
  
  def whens_hash
    { "Submit" => "submitted", "Approved" => "approved", "Rejected" => "rejected", "Committed" => "committed", "Graffiti" => "graffiti", "Never" => "never" }    
  end
  
  def find_sosol_users
    @emailer = Emailer.find(params[:id].to_s)
    @sosol_users = User.all
  end
  
  def add_member
   @emailer = Emailer.find(params[:id].to_s)
   user = User.find_by_name(params[:user_name].to_s)
   
    if nil == @emailer.users.find_by_id(user.id) 
      @emailer.users << user
      @emailer.save
    end   
  
   
   #redirect_to :action => "edit", :id => @emailer.id
   redirect_to :controller => "boards", :action => "edit", :id => @emailer.board
  end
  
  
  def remove_member
  
    user = User.find(params[:user_id].to_s)
    
    @emailer = Emailer.find(params[:id].to_s)
    @emailer.users.delete(user)
    @emailer.save            

    #redirect_to :action => "edit", :id => @emailer.id
    redirect_to :controller => "boards", :action => "edit", :id => @emailer.board
  end
  

  
  # GET /emailers
  # GET /emailers.xml
  def index
    @emailers = Emailer.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @emailers }
    end
  end

  # GET /emailers/1
  # GET /emailers/1.xml
  def show
    @emailer = Emailer.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @emailer }
    end
  end

  # GET /emailers/new
  # GET /emailers/new.xml
  def new
    @emailer = Emailer.new
    @emailer.board_id = params[:board_id]
    @board = Board.find(params[:board_id].to_s)
    @whens = whens_hash

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @emailer }
    end
  end

  # GET /emailers/1/edit
  def edit
    @emailer = Emailer.find(params[:id].to_s)
    @whens = whens_hash()
    #@whens = { "New" => "new", "Submitted" => "submitted", "Approved" => "approved", "Rejected" => "rejected", "Finalized" => "finalized", "Graffiti" => "graffiti", "Never" => "never" }
  end

  # POST /emailers
  # POST /emailers.xml
  def create
    @emailer = Emailer.new(emailer_params)
    
    if @emailer.save
      board = Board.find(@emailer.board_id)
      board.emailers << @emailer
      board.save
    
      flash[:notice] = 'Emailer was successfully created.'
      redirect_to :controller => 'emailers', :action => 'edit', :id => @emailer.id  
      #redirect_to :controller => 'boards', :action => 'edit', :id => @emailer.board.id  
        
    end
  end

  # PUT /emailers/1
  # PUT /emailers/1.xml
  def update
    @emailer = Emailer.find(params[:id].to_s)

    respond_to do |format|
      if params[:emailer].present? && @emailer.update_attributes(emailer_params)
        flash[:notice] = 'Emailer was successfully updated.'
        format.html { redirect_to :controller => 'boards', :action => 'edit', :id => @emailer.board.id  }
        #format.html { redirect_to(@emailer) }
        #format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @emailer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /emailers/1
  # DELETE /emailers/1.xml
  def destroy
    @emailer = Emailer.find(params[:id].to_s)
    @emailer.destroy

    respond_to do |format|
      format.html { redirect_to :controller => 'boards', :action => 'edit', :id => @emailer.board.id  }
      format.html { redirect_to(emailers_url) }
      format.xml  { head :ok }
    end
  end

  private

    def emailer_params
      params.require(:emailer).permit(:association,:extra_addresses,:include_document,:message,:board_id)
    end
end
