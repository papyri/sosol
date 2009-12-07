class PublicationsController < ApplicationController
  layout 'site'
  before_filter :authorize
  
  def new
  end
  
  
  def allow_submit?
    #check if publication has been changed by user
    allow = @publication.modified?
    
    allow = allow && @publication.status == "editing"
    return allow
    
    #below bypassed until we have return mechanism in place
    
    #check if any part of the publication is still being edited (ie not already submitted)
    if allow #something has been modified so lets see if they can submit it
      allow = false #dont let them submit unless something is in edit status
      @publication.identifiers.each  do |identifier|
        if identifier.nil? || identifier.status == "editing" 
          allow = true
        end        
      end
    end
   allow
  end
  
  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new()
    @publication.populate_identifiers_from_identifier(
      params[:pn_id])
    @publication.owner = @current_user
    
    @publication.creator = @current_user
    #@publication.creator_type = "User"
    #@publication.creator_id = @current_user
    
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
  
  def create_from_templates
    @publication = Publication.new_from_templates(@current_user)
    
    # need to remove repeat against publication model
    e = Event.new
    e.category = "created"
    e.target = @publication
    e.owner = @current_user
    e.save!
    
    flash[:notice] = 'Publication was successfully created.'
    #redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    redirect_to @publication
  end
  
  
  
  def submit_review
    @publication = Publication.find(params[:id])
    @comments = Comment.find_all_by_publication_id(params[:id])  
    @allow_submit = allow_submit?
            
    #redirect_to @publication
    # redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
  end
  
  def submit
    @publication = Publication.find(params[:id])
    
    @comment = Comment.new( {:publication_id => params[:id], :comment => params[:submit_comment], :reason => "submit" } )
    @comment.save
    @publication.submit
    
    flash[:notice] = 'Publication submitted.'
    redirect_to @publication
    # redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
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
  
  def finalize_review
    @publication = Publication.find(params[:id])
    @identifier = @publication.entry_identifier
    @diff = @publication.diff_from_canon
  end
  
  def finalize
    @publication = Publication.find(params[:id])
    @publication.commit_to_canon
    
    flash[:notice] = 'Publication finalized.'
    redirect_to @publication
  end
  
  # GET /publications/1
  # GET /publications/1.xml
  def show

    @publication = Publication.find(params[:id])
    @comments = Comment.find_all_by_publication_id(params[:id])

    @show_submit = allow_submit?

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
  
  def edit_trans  
    @publication = Publication.find(params[:id])    
    @identifier = HGVTransIdentifier.find_by_publication_id(@publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])    
  end
  
  def vote  

    @vote = Vote.new(params[:vote])
    @vote.user_id = @current_user.id
    
    #find identifier to put vote on
    
    #tally votes for identifier
    
    #run method for result
    puts "id = " + @vote.identifier_id.to_s
    
    #double check that they have not already voted
    has_voted = @vote.identifier.votes.find_by_user_id(@current_user.id)
    if !has_voted 
      @vote.save   
          
#todo add comment to vote
      
      #need to tally votes and see if any action will take place
      #should only be voting while the publication is owned by the correct board
      #todo add check to ensure board is correct
      decree_action = @vote.publication.owner.tally_votes(@vote.identifier.votes)
      
      #arrrggg status vs action....could assume that voting will only take place if status is submitted, but that will limit our workflow options?
      #NOTE here are the types of actions for the voting results
      #approve, reject, graffiti
      
      # create an event if anything happened
      if !decree_action.nil? && decree_action != ''
        e = Event.new
        e.owner = @vote.publication.owner
        e.target = @vote.publication
        e.category = "marked as \"#{decree_action}\""
        e.save!
      end
    
    
      if decree_action == "approve"
        #@publication.get_category_obj().approve
        @vote.identifier.status = "approved"
        @vote.save
        #@publication.status = "approved"
        #@publication.save
        # @publication.send_status_emails(decree_action)    
      elsif decree_action == "reject"
        #todo implement throughback
        @vote.identifier.status = "reject"     
        @vote.save
        # @publication.send_status_emails(decree_action)
      elsif decree_action == "graffiti"               
        # @publication.send_status_emails(decree_action)
        #do destroy after email since the email may need info in the artice
        #@publication.get_category_obj().graffiti
        @vote.identifier.destroy #need to destroy related?
        #this part of the publication was crap, do we assume the rest is as well?
        #for now we will just continue the submition process
        self.submit_to_next_board
        
        #redirect_to url_for(dashboard)
        return
      else
        #unknown action or no action    
      end   
    

 # unsure if following needed due to merge conflict
 #     if !Publication.exists?(@publication)
 #       redirect_to url_for(dashboard)
 #     end

    end #!has_voted
    #do what now? go to review page
    
    redirect_to edit_polymorphic_path([@vote.publication, @vote.publication.entry_identifier])
    #todo redirect to publication summary page
  end
  
  
  
  
  
  # DELETE 
  def destroy
    @publication = Publication.find(params[:id])
    pub_name = @publication.title
    @publication.destroy


    e = Event.new
    e.category = "deleted"
    e.target = @publication
    e.owner = @current_user
    e.save!
    
    flash[:notice] = 'Publication ' + pub_name + ' was successfully deleted.'
    respond_to do |format|
      format.html { redirect_to dashboard_url }
      
    end
  end
  
  
  
  
end
