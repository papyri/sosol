class BoardsController < ApplicationController

  layout "site"
  before_filter :check_admin

  def check_admin
    if !@current_user.admin
      render :file => 'public/403.html', :status => '403'
    end
  end
  
  
  def find_member
    @board = Board.find(params[:id])
  end

  def add_member
    @board = Board.find(params[:id])
    user = User.find_by_name(params[:user_name])

    if nil == @board.users.find_by_id(user.id) 
      @board.users << user
      @board.save
    end

    redirect_to :action => "edit", :id => (@board).id
  end

  def remove_member
    user = User.find(params[:user_id])

    @board = Board.find(params[:id])
    @board.users.delete(user)
    @board.save

    redirect_to :action => "edit", :id => (@board).id
  end

  # GET /boards
  # GET /boards.xml
  def index
    @boards = Board.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @boards }
    end
  end

  # GET /boards/1
  # GET /boards/1.xml
  def show
    @board = Board.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @board }
    end
  end

  # GET /boards/new
  # GET /boards/new.xml
  def new
    @board = Board.new
    @valid_identifier_classes = Identifier::IDENTIFIER_SUBCLASSES
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @board }
    end
  end

  # GET /boards/1/edit
  def edit
    @board = Board.find(params[:id])
  end

  # POST /boards
  # POST /boards.xml
  def create
    @board = Board.new(params[:board])
    
    @board.identifier_classes = []
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      if params.has_key?(identifier_class) && params[identifier_class] == "1"
        @board.identifier_classes << identifier_class
      end
    end

    if @board.save
      flash[:notice] = 'Board was successfully created.'
      redirect_to :action => "edit", :id => (@board).id    
    end         
#    respond_to do |format|
#      if @board.save
#        flash[:notice] = 'Board was successfully created.'
#        redirect_to :action => "edit", :id => (@board).id
        #format.html { redirect_to(@board) }
       # format.xml  { render :xml => @board, :status => :created, :location => @board }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @board.errors, :status => :unprocessable_entity }
#     end
#    end
  end

  # PUT /boards/1
  # PUT /boards/1.xml
  def update
    @board = Board.find(params[:id])

    respond_to do |format|
      if @board.update_attributes(params[:board])
        flash[:notice] = 'Board was successfully updated.'
        format.html { redirect_to(@board) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @board.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /boards/1
  # DELETE /boards/1.xml
  def destroy
    @board = Board.find(params[:id])
    @board.destroy

    respond_to do |format|
      format.html { redirect_to(boards_url) }
      format.xml  { head :ok }
    end
  end
end
