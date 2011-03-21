class BoardsController < ApplicationController

  layout "site"
  before_filter :authorize
  before_filter :check_admin

  
  def check_admin
    if @current_user.nil? || !@current_user.admin
      render :file => 'public/403.html', :status => '403'
    end
  end
  
  def overview
    @board = Board.find(params[:id])

    if @board.users.find_by_id(@current_user.id) || @current_user.developer
      # below is dangerous since it will expose publications to non owners
      #finalizing_publications = Publication.find(:all, :conditions => "status == 'finalizing'")
      
      #return only owner publications
      finalizing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions =>  { :status => 'finalizing'} )    

      if finalizing_publications
        @finalizing_publications = finalizing_publications.collect{|p| p.parent.owner == @board ? p :nil}.compact
      else
       @finalizing_publications = nil
      end
    else
      #dont let them have access
      redirect_to dashboard_url
      return
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
    #@boards = Board.find(:all)
    @boards = Board.ranked

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
    
    #don't let more than one board use the same identifier class
    @available_identifier_classes = Array.new(Identifier::IDENTIFIER_SUBCLASSES)
    #TODO - is Biblio needed?
    #@available_identifier_classes.delete("HGVBiblioIdentifier")
    #existing_boards = Board.find(:all)
    #existing_boards.each do |b|
    #  @available_identifier_classes -= b.identifier_classes
    #end
     
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

    #let them choose as many ids as they want
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      if params.has_key?(identifier_class) && params[identifier_class] == "1"
        @board.identifier_classes << identifier_class
      end
    end

    #just let them choose one identifer class
    #@board.identifier_classes << params[:identifier_class]

    #put the new board in last rank
    #TODO add count for community
    @board.rank = Board.count()  + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.

    if @board.save
      flash[:notice] = 'Board was successfully created.'
      redirect_to :action => "edit", :id => (@board).id    
    end         
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


  def rank
    @boards = Board.ranked;
  end

  def update_rankings

    @boards = Board.find(:all)

    rankings = params[:ranking].split(',');
    
    rank_count = 1
    rankings.each do |rank_id|
      @boards.each do |board|
        if (board.id == rank_id.to_i)
          board.rank = rank_count
          board.save!
          break;
        end
      end
      rank_count+= 1
    end
    redirect_to :action => "index"
  end


end
