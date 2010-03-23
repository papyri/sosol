class PublicationsController < ApplicationController
  layout 'site'
  before_filter :authorize
  
  protect_from_forgery :only => []
  
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
    allow = allow && ((@publication.status == "editing") || (@publication.status == "new"))
    
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
    @creatable_identifiers = Array.new(Identifier::IDENTIFIER_SUBCLASSES)
        @publication.identifiers.each do |i|
          @creatable_identifiers.each do |ci|
            Rails.logger.info("Creatable identifier: #{ci}")
            if ci == i.class.to_s
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
    
    
    #@comment = Comment.new( {:git_hash => @publication.recent_submit_sha, :publication_id => params[:id], :comment => params[:submit_comment], :reason => "submit", :user_id => @current_user.id } )
    #git hash is not yet known, but we need the comment for the publication.submit to add to the changeDesc
    @comment = Comment.new( {:publication_id => params[:id], :comment => params[:submit_comment], :reason => "submit", :user_id => @current_user.id } )
    @comment.save
    
    @publication.submit    

    @comment.git_hash = @publication.recent_submit_sha
    @comment.save

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
    @identifier = nil#@publication.entry_identifier
    #if we are finalizing then find the board that this pub came from 
    # and find the identifers that the board controls
    if @publication.parent.owner_type == "Board"
      @publication.identifiers.each do |id|
        if @publication.parent.owner.controls_identifier?(id)
          @identifier = id
          #TODO change to array if board can control multiple identifiers
        end
      end      
    end
    @diff = @publication.diff_from_canon
  end
  
  def finalize
    @publication = Publication.find(params[:id])
    canon_sha = @publication.commit_to_canon


    #go ahead and store a comment on finalize even if the user makes no comment...so we have a record of the action  
    @comment = Comment.new()
  
    if params[:comment] && params[:comment] != ""  
      @comment.comment = params[:comment]
    else
      @comment.comment = "no comment"
    end
    @comment.user = @current_user
    @comment.reason = "finalizing"
    @comment.git_hash = canon_sha
    #associate comment with original identifier/publication
    @comment.identifier_id = params[:identifier_id]
    @comment.publication = @publication.origin
    
    @comment.save
  

    
    #TODO need to submit to next board
    #need to set status of ids
    @publication.set_origin_and_local_identifier_status("committed")
    @publication.set_board_identifier_status("committed")
    
    #as it is set up the finalizer will have a parent that is a board whose status must be set
    #check that parent is board
    if @publication.parent && @publication.parent.owner_type == "Board"              
      @publication.parent.status = "committed"
      @publication.parent.save
      @publication.parent.owner.send_status_emails("committed", @publication)
    #else #the user is a super user
    end
         
        

    
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
    
    #only let creator delete
    @allow_delete = @current_user.id == @publication.creator.id 
    #only delete new or editing
    @allow_delete = @allow_delete && (@publication.status == "new" || @publication.status == "editing")  
    
    #todo - if any part has been approved, do we want them to be able to delete the publication or force it to an archve? this would only happen if a board returns their part after another board has approved their part
    

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
    @publication = Publication.find(params[:id])
    @identifier = DDBIdentifier.find_by_publication_id(@publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
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

  def edit_biblio
    @publication = Publication.find(params[:id])
    @identifier = HGVBiblioIdentifier.find_by_publication_id(@publication.id)
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end

  def create_from_selector
    identifier_class = params[:IdentifierClass]
    collection = params["#{identifier_class}CollectionSelect".intern]
    volume = params[:volume_number]
    document = params[:document_number]
    
    if identifier_class == 'DDBIdentifier'
      document_path = [collection, volume, document].join(';')
    elsif identifier_class == 'HGVIdentifier'
      collection = collection.tr(' ', '_')
      if volume.empty?
        document_path = [collection, document].join('_')
      else
        document_path = [collection, volume, document].join('_')
      end
    end
    
    namespace = identifier_class.constantize::IDENTIFIER_NAMESPACE
    
    identifier = [NumbersRDF::NAMESPACE_IDENTIFIER, namespace, document_path].join('/')
    
    if identifier_class == 'HGVIdentifier'
      identifier = NumbersRDF::NumbersHelper.identifier_to_identifier(identifier)
    end

    Rails.logger.info("Identifier: #{identifier}")
    
    related_identifiers = NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier)
    
    conflicting_identifiers = []
    related_identifiers.each do |relid|
      possible_conflicts = Identifier.find_all_by_name(relid, :include => :publication)
      actual_conflicts = possible_conflicts.select {|pc| pc.publication.owner == @current_user}
      conflicting_identifiers += actual_conflicts
    end
    
    if related_identifiers.length == 0
      flash[:notice] = 'Error creating publication: publication not found'
      redirect_to dashboard_url
      return
    elsif conflicting_identifiers.length > 0
      conflicting_publication = conflicting_identifiers.first.publication
      conflicting_identifiers.each do |confid|
        if confid.publication != conflicting_publication
          flash[:notice] = 'Error creating publication: multiple conflicting publications'
          redirect_to dashboard_url
          return
        end
      end
      
      if (conflicting_publication.status == "committed")
        # TODO: should set "archived" and take approp action here instead
        #conflicting_publication.destroy
        conflicting_publication.archive
      else
        flash[:notice] = 'Error creating publication: publication already exists. Please delete the conflicting publication if you have not submitted it and would like to start from scratch.'
        redirect_to dashboard_url
        return
      end
    end
    # else
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
    # end
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
    #use most recent sha from identifier
    @comment.git_hash = @vote.identifier.get_recent_commit_sha
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
  
  def confirm_archive
    @publication = Publication.find(params[:id])
  end
  
  def archive
    @publication = Publication.find(params[:id])
    @publication.archive
    redirect_to @publication    
  end
  
  
  
  def confirm_delete
    @publication = Publication.find(params[:id])
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
