class EmailersController < ApplicationController
  def find_board_member
    @emailer = Emailer.find(params[:id])
  end
  
  def add_member
   @emailer = Emailer.find(params[:id])
   user = User.find_by_name(params[:user_name])
   
    if nil == @emailer.users.find_by_id(user.id) 
      @emailer.users << user
      @emailer.save
    end   
  
   redirect_to :action => "edit", :id => @emailer.id
  end
  
  
  def remove_member
  
    user = User.find(params[:user_id])
    
    @emailer = Emailer.find(params[:id])
    @emailer.users.delete(user)
    @emailer.save            

    redirect_to :action => "edit", :id => @emailer.id
  end
  

  
  # GET /emailers
  # GET /emailers.xml
  def index
    @emailers = Emailer.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @emailers }
    end
  end

  # GET /emailers/1
  # GET /emailers/1.xml
  def show
    @emailer = Emailer.find(params[:id])

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
    @board = Board.find(params[:board_id])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @emailer }
    end
  end

  # GET /emailers/1/edit
  def edit
    @emailer = Emailer.find(params[:id])
    @whens = { "New" => "new", "Submitted" => "submitted", "Approved" => "approved", "Rejected" => "rejected", "Finalized" => "finalized", "Graffiti" => "graffiti", "Never" => "never" }
  end

  # POST /emailers
  # POST /emailers.xml
  def create
    @emailer = Emailer.new(params[:emailer])
    
    if @emailer.save
      board = Board.find(@emailer.board_id)
      board.emailers << @emailer
      board.save
    
      flash[:notice] = 'Emailer was successfully created.'
      redirect_to :controller => 'boards', :action => 'edit', :id => @emailer.board.id  
        
    end
  end

  # PUT /emailers/1
  # PUT /emailers/1.xml
  def update
    @emailer = Emailer.find(params[:id])

    respond_to do |format|
      if @emailer.update_attributes(params[:emailer])
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
    @emailer = Emailer.find(params[:id])
    @emailer.destroy

    respond_to do |format|
      format.html { redirect_to(emailers_url) }
      format.xml  { head :ok }
    end
  end
end
