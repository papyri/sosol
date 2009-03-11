class ArticlesController < ApplicationController
  layout 'site'
  
  def begin
  
  end
  
  def new_from_pn
  
  end
  
  def comment_on
  	@article = Article.find(params[:id])
  	@comment = Comment.new()
  end
  
  def list_all
    @articles = Article.find(:all)
  end
  
  # GET /articles
  # GET /articles.xml
  def index
    @articles = Article.find(:all)
    if !@current_user.nil?
      @branches = @current_user.repository.branches
      @branches.delete("master")
    else
      @branches = []
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @articles }
    end
  end

  # GET /articles/1
  # GET /articles/1.xml
  def show
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/new
  # GET /articles/new.xml
  def new
    @article = Article.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/1/edit
  def edit
    editxml
  end
  
  # GET /articles/1/xml
  def editxml
    @article = Article.find(params[:id])
  end
  
  def preview
    editxml
    
    Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
    xslt = XML::XSLT.new()
    xslt.xml = REXML::Document.new(@article.content)
    xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    
    @transformed = xslt.serve()
  end

  # POST /articles
  # POST /articles.xml
  def create
    @article = Article.new(params[:article])
    # TODO: filter
    @article.user_id = @current_user.id unless @current_user.nil?
    @article.category = params[:category]

    respond_to do |format|
      if @article.save
        flash[:notice] = 'Article was successfully created.'
        format.html { redirect_to(@article) }
        format.xml  { render :xml => @article, :status => :created, :location => @article }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Article.find(params[:id])

    respond_to do |format|
      if true || @article.update_attributes(params[:article])
        flash[:notice] = 'Article was successfully updated.'
        format.html { redirect_to(@article) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end
end
