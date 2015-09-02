class BoardsController < ApplicationController

  #layout "site"
  #layout "header_footer"
  before_filter :authorize
  before_filter :check_admin

  #Ensures user has admin rights to view page. Otherwise returns 403 error.
  def check_admin
    if @current_user.nil? || !@current_user.admin
      render :file => 'public/403.html', :status => '403'
    end
  end
  
  #Presents overview for publication.
  def overview
    @board = Board.find(params[:id].to_s)

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
    @board = Board.find(params[:id].to_s)
  end

  #Adds the user to the board member list.
  def add_member
    @board = Board.find(params[:id].to_s)
    user = User.find_by_name(params[:user_name].to_s)

    if nil == @board.users.find_by_id(user.id) 
      @board.users << user
      @board.save
    end

    redirect_to :action => "edit", :id => (@board).id
  end

  #Removes a member from the board member list.
  def remove_member
    user = User.find(params[:user_id].to_s)

    @board = Board.find(params[:id].to_s)
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
    @board = Board.find(params[:id].to_s)

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

    #existing_boards = Board.find(:all)
    #existing_boards.each do |b|
    #  @available_identifier_classes -= b.identifier_classes
    #end
    
    if params[:community_id].to_s
      @board.community_id =  params[:community_id].to_s
    end
     
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @board }
    end
  end

  # GET /boards/1/edit
  def edit
    @board = Board.find(params[:id].to_s)
  end

  # POST /boards
  # POST /boards.xml
  def create


    @board = Board.new(params[:board])
    
    @board.identifier_classes = []

    #let them choose as many ids as they want
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      if params.has_key?(identifier_class) && params[identifier_class].to_s == "1"
        @board.identifier_classes << identifier_class
      end
    end



    #put the new board in last rank
    if @board.community_id
      @board.rank = Board.ranked_by_community_id( @board.community_id ).count  + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.
    else
      #@board.rank = Board.count()  + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.  
      @board.rank = Board.ranked.count  + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.
    end
    #just let them choose one identifer class
    #@board.identifier_classes << params[:identifier_class]
    

    if @board.save
      flash[:notice] = 'Board was successfully created.'
      redirect_to :action => "edit", :id => (@board).id
    else
      #TODO add error check to give meaningfull response to user.
      flash[:error] = 'Board creation failed. Was your name unique?'
      redirect_to dashboard_url
    end         
  end

  # PUT /boards/1
  # PUT /boards/1.xml
  def update
    @board = Board.find(params[:id].to_s)

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
    @board = Board.find(params[:id].to_s)
    @board.destroy

    respond_to do |format|
      format.html { redirect_to(boards_url) }
      format.xml  { head :ok }
    end
  end

  #*Returns* array of boards sorted by rank. Lowest rank (highest priority) first.
  #If community_id is given then the returned boards are only for that community.
  #If no community_id is given then the "sosol" boards are returned. 
  def rank
    if params[:community_id].to_s
      @boards = Board.ranked_by_community_id( params[:community_id].to_s )
      @community_id = params[:community_id].to_s 
    else
      #default to sosol boards
      @boards = Board.ranked;  
    end
    
  end

  #Sorts board rankings by given array of board id's and saves new rankings.
  def update_rankings

    if params[:community_id].to_s
      @boards = Board.ranked_by_community_id( params[:community_id].to_s )
    else
      #default to sosol boards
      @boards = Board.ranked;  
    end
    
    #@boards = Board.find(:all)

    rankings = params[:ranking].to_s.split(',');
    
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
    
    
    if params[:community_id].to_s
      redirect_to :controller => 'communities', :action => 'edit',  :id => params[:community_id].to_s
      return
    else
      #default to sosol boards
      redirect_to :action => "index"
      return
    end
    
  end


def send_board_reminder_emails
    
  addresses = Array.new 
  
  if (params[:community_id].to_s != '')
    boards = Board.ranked_by_community_id(params[:community_id].to_s) 
    community = Community.find_by_id(params[:community_id].to_s) 
  else
    boards = Board.ranked
  end
    
    
  body_text = 'Greetings '
  if community
    body_text += community.name + " "
  end
  time_str = Time.now.strftime("%Y-%m-%d")
  body_text += "Board Members, as of " + time_str  + ", "
  boards.each do |board|
    #grab addresses for this board 
    board.users.each do |board_user|          
      addresses << board_user.email        
    end
  
    body_text += "\n" + board.name + " has " 
      
    #find all pubs that are still in voting phase         
    voting_publications = board.publications.collect{|p| p.status == 'voting' ? p : nil}.compact
    #voting_publications = Publication.find_all_by_owner_id(board.id, :conditions => {:owner_type => 'Board', :status => "voting"}  )
    if voting_publications
      body_text += voting_publications.length.to_s
    else
      body_text += "no"
    end
    body_text += " publications requiring voting action, "
    
    body_text += " and "
  
    approved_publications = board.publications.collect{|p| p.status == 'approved' ? p : nil}.compact
    #approved_publications = Publication.find_all_by_owner_id(board.id, :conditions => {:owner_type => "Board", :status => "approved" }  )
    if approved_publications
      body_text += approved_publications.length.to_s
    else
      body_text += "no"
    end
    body_text += " approved publications waiting to be finalized.  "    
    
    
    completed_publications = board.publications.collect{|p| (p.status == 'committed' || p.status == 'archived') ? p : nil}.compact
    
    if completed_publications
      body_text += completed_publications.length.to_s
    else
      body_text += "No"
    end
    body_text += " publications have been committed."
    
    
    subject_line = ""
    if community
      subject_line += community.name + " "
    end  
    subject_line += "Board Publication Status Reminder " 
    
    addresses.each do |address|
      if address && address.strip != ""
        begin
          EmailerMailer.general_email(address, subject_line, body_text).deliver
        rescue Exception => e
          Rails.logger.error("Error sending email: #{e.class.to_s}, #{e.to_s}")
        end
      end
    end   
  end
  
  
  if community 
    flash[:notice] = "Notifications sent to all " + community.name + " board members."
  else
    flash[:notice] = "Notifications sent to all PE board members."
  end
  redirect_to dashboard_url
end

def confirm_destroy
  @board = Board.find(params[:id].to_s)
end

end
