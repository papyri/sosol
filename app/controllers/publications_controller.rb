class PublicationsController < ApplicationController
  layout 'site'
  before_filter :authorize
  
  def new
  end
  
  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new()
    @publication.populate_identifiers_from_identifier(
      params[:pn_id])
    @publication.owner = @current_user
    
    if @publication.save
      @publication.branch_from_master
      
      # need to remove repeat against publication model
      e = Event.new
      e.category = "started editing"
      e.target = @publication
      e.owner = @current_user
      e.save!
      
      flash[:notice] = 'Publication was successfully created.'
      redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    else
      flash[:notice] = 'Error creating publication'
      redirect_to dashboard_url
    end
  end
  
  def submit
    @publication = Publication.find(params[:id])
    @publication.submit
    
    flash[:notice] = 'Publication submitted.'
    redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
  end
  
  # GET /publications
  # GET /publications.xml
  def index
    @branches = @current_user.repository.branches
    @branches.delete("master")
    
    @publications = Publication.find_all_by_owner_id(@current_user.id)
    # just give branches that don't have corresponding publications
    @branches -= @publications.map{|p| p.branch}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @publications }
    end
  end
  
  # GET /publications/1
  # GET /publications/1.xml
  def show
    @publication = Publication.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @publication }
    end
  end
  
  # GET /publications/1/edit
  def edit
    @publication = Publication.find(params[:id])
    
    redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
  end
  
  def edit_text
    edit
  end
  
  def edit_meta
    @publication = Publication.find(params[:id])
    @identifier = HGVMetaIdentifier.find_by_publication_id(@publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end
  
  def vote            
    @vote = Vote.new(params[:vote])
    @publication = Publication.find(params[:id])   
    
    #double check that they have not already voted
    has_voted = @publication.votes.find_by_user_id(@current_user.id)
    if !has_voted 
      @vote.user_id = @current_user.id
      @vote.save   
      @publication.votes << @vote
          
      # @comment = Comment.new()
      # @comment.article_id = params[:id]
      # @comment.text = params[:comment]
      # @comment.user_id = @current_user.id
      # @comment.reason = "vote"
      # @comment.save
      
      #TODO tie vote and comment together?  
      
      #need to tally votes and see if any action will take place
      decree_action = @publication.owner.tally_votes(@publication.votes)
      #arrrggg status vs action....could assume that voting will only take place if status is submitted, but that will limit our workflow options?
      #NOTE here are the types of actions for the voting results
      #approve, reject, graffiti
      
      # create an event if anything happened
      if !decree_action.nil? && decree_action != ''
        e = Event.new
        e.owner = @publication.owner
        e.target = @publication
        e.category = "marked as \"#{decree_action}\""
        e.save!
      end
    
    
      if decree_action == "approve"
        #@publication.get_category_obj().approve
        @publication.status = "approved"
        @publication.save
        # @publication.send_status_emails(decree_action)    
      elsif decree_action == "reject"
        #@publication.get_category_obj().reject       
        @publication.status = "new" #reset to unsubmitted       
        @publication.save
        # @publication.send_status_emails(decree_action)
      elsif decree_action == "graffiti"               
        # @publication.send_status_emails(decree_action)
        #do destroy after email since the email may need info in the artice
        #@publication.get_category_obj().graffiti
        @publication.destroy #need to destroy related?
        redirect_to url_for(dashboard)
        return
      else
        #unknown action or no action    
      end   
    
    end #!has_voted
    #do what now? go to review page
    
    redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
  end
end