class PublicationsController < ApplicationController
  layout 'site'
  before_filter :authorize
  
  def new
  end
  
  
  def allow_submit?
    #check if publication has been changed by user
    allow = @publication.modified?
    
    #only let creator submit
    allow = allow && @publication.creator_id == @current_user.id 
    
    #only let user submit, don't let a board member submit
    allow = allow && @publication.owner_type == "User"
    
    #dont let user submit if already submitted, or committed etc..
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
  
  def determine_creatable_identifiers
    #only let user create new for non-existing    
    @creatable_identifiers = Identifier::IDENTIFIER_SUBCLASSES
        @publication.identifiers.each do |i|
          @creatable_identifiers.each do |ci|
            puts ci
            if ci == i.type.to_s
              @creatable_identifiers.delete(ci)    
            end
          end
        end  
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
    @comments = Comment.find_all_by_publication_id(@publication.origin.id)  
    @allow_submit = allow_submit?
            
    #redirect_to @publication
    # redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
  end
  
  def submit
    @publication = Publication.find(params[:id])
    
    @comment = Comment.new( {:publication_id => params[:id], :comment => params[:submit_comment], :reason => "submit", :user_id => @current_user.id } )
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
  
  def become_finalizer
    #TODO make sure we don't steel it from someone who is working on it
    
    
    
    @publication = Publication.find(params[:id])
    
    
    @publication.remove_finalizer
    
    #note this can only be called on a board owned publication
    if @publication.owner_type != "Board"
      flash[:error] = "Can't change finalizer on non-board copy of publication."
      redirect_to show
    end
    @publication.send_to_finalizer(@current_user)
    redirect_to (dashboard_url) #:controller => "publications", :action => "finalize_review" , :id => new_publication_id
  
  end
  
  def finalize_review
    @publication = Publication.find(params[:id])
    @identifier = @publication.entry_identifier
    @diff = @publication.diff_from_canon
  end
  
  def finalize
    @publication = Publication.find(params[:id])
    @publication.commit_to_canon
    
    #TODO need to submit to next board
    #need to set status of ids
    @publication.set_origin_and_local_identifier_status("committed")
    @publication.set_board_identifier_status("committed")
    
    #as it is set up the finalizer will have a parent that is a board whose status must be set
    @publication.parent.status = "committed"
    @publication.parent.save
    
    #set the finalizer pub status
    @publication.status = "committed"
    @publication.save
    
    
    #send publication to the next board
    @publication.origin.submit_to_next_board
    
    flash[:notice] = 'Publication finalized.'
    redirect_to @publication
  end
  
  # GET /publications/1
  # GET /publications/1.xml
  def show
    
    begin
      @publication = Publication.find(params[:id])
    rescue    
      flash[:error] = "Publication not found"
      redirect_to (dashboard_url)
      return
    end
     
    @comments = Comment.find_all_by_publication_id(@publication.origin.id, :order => 'created_at DESC')

    @show_submit = allow_submit?

    determine_creatable_identifiers()
    
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
  
  def create_from_selector
    identifier_class = params[:IdentifierClass]
    collection = params["#{identifier_class}CollectionSelect".intern]
    volume = params[:volume_number]
    document = params[:document_number]
    
    if identifier_class == 'DDBIdentifier'
      collection = DDBIdentifier.ddb_human_collection_to_series(collection)
    elsif identifier_class == 'HGVIdentifier'
      collection = URI.escape(collection)
    end
    
    namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE
    identifier = [NumbersRDF::PREFIX, 
      namespace, collection, volume, document].join(':')

    Rails.logger.info("Identifier: #{identifier}")
    
    related_identifiers = NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier)
    
    if related_identifiers.length == 0
      flash[:notice] = 'Error creating publication: publication not found'
      redirect_to dashboard_url
    else
      @publication = Publication.new()
      @publication.populate_identifiers_from_identifier(
        identifier)
      @publication.owner = @current_user

      @publication.creator = @current_user

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
  end
  
  def vote
    #note that votes will go with the boards copy of the pub and identifiers
    #  vote history will also be recorded in the comment of the origin pub and identifier
    
    #if not pub found ie race condition of voting on reject or graffiti    
    begin
      @publication = Publication.find(params[:id])  
    rescue    
      flash[:warning] = "Publication not found - voting is over for this publications."
      redirect_to (dashboard_url)
      return
    end
    
    
    
    if @publication.status != "voting" 
      flash[:warning] = "Voting is over for this publication."
      
      redirect_to @publication
      return
    end
    
    #note that votes go to origin identifier
    @vote = Vote.new(params[:vote])
    @vote.user_id = @current_user.id      
    
    if @publication.owner_type != "Board"
      #we have a problem since no one should be voting on a publication if it is not in theirs
      flash[:error] = "You do not have permission to vote on this publication which you do not own!"
      #kind a harsh but send em back to their own dashboard
      redirect_to dashboard_url
      return
    else
      @vote.board_id = @publication.owner_id
    end
    
    @comment = Comment.new()
    @comment.comment = @vote.choice + " - " + params[:comment][:comment]
    @comment.user = @current_user
    @comment.reason = "vote"
    #associate comment with original identifier/publication
    @comment.identifier = @vote.identifier.origin   
    @comment.publication = @vote.publication.origin

    #double check that they have not already voted
    has_voted = @vote.identifier.votes.find_by_user_id(@current_user.id)
    if !has_voted 
      @vote.save
      @comment.save
    end #!has_voted
    #do what now? go to review page
    
    # unsure if following needed due to merge conflict
    #     if !Publication.exists?(@publication)
    #       redirect_to url_for(dashboard)
    #     end
    
        #redirect_to edit_polymorphic_path([@vote.publication, @vote.publication.entry_identifier])


    begin
      #see if publication still exists
      Publication.find(params[:id])
      redirect_to @publication
      return
    rescue
      #voting destroyed publication so go to the dashboard
      redirect_to dashboard_url
      return
    end
   
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
  
  
  def master_list
    if @current_user.developer
      @publications = Publication.find(:all)
    else
      redirect_to dashboard_url
    end
  end
  
end
