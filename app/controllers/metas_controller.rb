class MetasController < ApplicationController

  layout 'site'
 
 
 def submit
 
 
   @meta = Meta.find(params[:id])
 
   if (params[:comment] == nil || params[:comment] == "")
     flash[:notice] = 'You must provide reasoning.'
     redirect_to :action => "review_for_submit", :id => params[:id]
   else
	 
	   comment = Comment.new()
	   comment.article_id = params[:id]
	   comment.text = params[:comment]
	   comment.user_id = @current_user.id
	   comment.reason = "submit"
	   comment.save()
	   
	   @meta.article.comments << comment
	   @meta.article.status = "submitted"
	   @meta.article.save()  #need to save here?
	   @meta.save()
	   
	   flash[:notice] = 'Meta has been submitted.'
	   redirect_to  url_for(@meta.article.master_article)
   end   
 end
 
 def review_for_submit
   @meta = Meta.find(params[:id])
 
 end
 
 
  # GET /metas
  # GET /metas.xml
  def index
    @metas = Meta.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @metas }
    end
  end

  # GET /metas/1
  # GET /metas/1.xml
  def show
    @meta = Meta.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @meta }
    end
  end

  # GET /metas/new
  # GET /metas/new.xml
  def new
    @meta = Meta.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @meta }
    end
  end

  # GET /metas/1/edit
  def edit
    @meta = Meta.find(params[:id])
  end

  # POST /metas
  # POST /metas.xml
  def create
    @meta = Meta.new(params[:meta])

    respond_to do |format|
      if @meta.save
        flash[:notice] = 'Meta was successfully created.'
        format.html { redirect_to(@meta) }
        format.xml  { render :xml => @meta, :status => :created, :location => @meta }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @meta.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /metas/1
  # PUT /metas/1.xml
  def update
    @meta = Meta.find(params[:id])

    respond_to do |format|
      if @meta.update_attributes(params[:meta])
        flash[:notice] = 'Meta was successfully updated.'
        format.html { redirect_to(@meta) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @meta.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /metas/1
  # DELETE /metas/1.xml
  def destroy
    @meta = Meta.find(params[:id])
    @meta.destroy

    respond_to do |format|
      format.html { redirect_to(metas_url) }
      format.xml  { head :ok }
    end
  end
end
