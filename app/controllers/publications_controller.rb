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
      params[:publication][:pn_id])
    @publication.owner = @current_user
    
    if @publication.save
      flash[:notice] = 'Publication was successfully created.'
      redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
    end
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
end