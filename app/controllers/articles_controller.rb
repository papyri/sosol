require 'net/http' 

class ArticlesController < ApplicationController
  layout 'site'
  
  def board_review
    @article = Article.find(params[:id])
    @vote = Vote.new()
  
  end
  
  def vote
    @vote = Vote.new(params[:vote])
    @article = Article.find(params[:id])
    
    @vote.user_id = @current_user.id
    @vote.save
    @article.votes << @vote
    
    
	@comment = Comment.new()
	@comment.article_id = params[:id]
	@comment.text = params[:comment]
	@comment.user_id = @current_user.id
	@comment.reason = "vote"
	@comment.save
	
	#TODO tie vote and comment together?	
	
	#do what now? go to review page
	render :controller => "articles", :action => "board_review", :id => @article.id
  end
  
  def new_meta
    #@article = Article.new
    @meta = Meta.new
  end
  
  def chuck_test
    get_pn_file("oai:papyri.info:identifiers:apis:michigan:2503")
    
  end
  

  def get_pn_file(control_name)
    baseUrl = "apptest.cul.columbia.edu"
    url = "/navigator/portal/apisfull.psml?controlName=" + control_name
   # baseUrl = "www.mybit.net"
    http = Net::HTTP.start(baseUrl, 8082)

      resp = http.get(url) 
      render :inline => "<%= resp %>", :locals => { :resp => resp.body }
   
  end

  
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
    @article.user_id = @current_user.id
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
