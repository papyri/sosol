require 'net/http' 

class ArticlesController < ApplicationController
  layout 'site'
  
  
  def review_for_submit
  	@article = Article.find(params[:id])
  end
  
  
  def board_review
    @article = Article.find(params[:id])
    @vote = Vote.new()
  end
  
  def review_for_finalize
  	@article = Article.find(params[:id])
  end
  
  
  
  def finalize  
  	@article = Article.find(params[:id])
 		@article.status = "finalized"
 		@article.save
 		@article.send_status_emails(@article.status)
 		#where to redirect to? or give message
 		#use standard finlized in category article? 		
  end
  
  def vote            
    @vote = Vote.new(params[:vote])
    @article = Article.find(params[:id])   
    
    #double check that they have not already voted
    has_voted = @article.votes.find_by_user_id(@current_user.id)
    if !has_voted 
		
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
			
			#need to tally votes and see if any action will take place
			decree_action = @article.board.tally_votes(@article.votes)
			#arrrggg status vs action....could assume that voting will only take place if status is submitted, but that will limit our workflow options?
			#NOTE here are the types of actions for the voting results
			#approve, reject, graffiti
		
		
			
			if decree_action == "approve"
				#@article.get_category_obj().approve
				@article.status = "approved"
				@article.save
				@article.send_status_emails(decree_action)		
			elsif decree_action == "reject"
				#@article.get_category_obj().reject				
				@article.status = "new" #reset to unsubmitted				
				@article.save
				@article.send_status_emails(decree_action)
			elsif decree_action == "graffiti"								
				@article.send_status_emails(decree_action)
				#do destroy after email since the email may need info in the artice
				#@article.get_category_obj().graffiti
				master_article = @article.master_article
				@article.destroy #need to destroy related?
				redirect_to  url_for(master_article)
				return
			else
				#unknown action or no action		
			end		
		
		end #!has_voted
		#do what now? go to review page
		
		render :controller => "articles", :action => "board_review", :id => @article.id
  end
  
  
  def submit
 
		@article = Article.find(params[:id])

		comment = Comment.new()
		comment.article_id = params[:id]
		comment.text = params[:comment]
		comment.user_id = @current_user.id
		comment.reason = "submit"
		comment.save()

		@article.comments << comment
		@article.status = "submitted"
		@article.save()
		
		#status has changed
		@article.send_status_emails(@article.status)

		flash[:notice] = 'Article has been submitted.'
		redirect_to  url_for(@article.master_article)
    
 	end
  
  
  
#  def new_meta
#    #@article = Article.new
#    @meta = Meta.new
#  end
  
#  def chuck_test
#    get_pn_file("oai:papyri.info:identifiers:apis:michigan:2503")    
#  end
  

#  def get_pn_file(control_name)
#    baseUrl = "apptest.cul.columbia.edu"
#    url = "/navigator/portal/apisfull.psml?controlName=" + control_name
#   # baseUrl = "www.mybit.net"
#    http = Net::HTTP.start(baseUrl, 8082)
#      resp = http.get(url) 
#      render :inline => "<%= resp %>", :locals => { :resp => resp.body }   
#  end

  
#  def begin
  
#  end
  
#  def new_from_pn
  
#  end
  
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
#  def edit
#    editxml
#  end
  
  # GET /articles/1/xml
#  def editxml
#    @article = Article.find(params[:id])
#  end
  
#  def preview
#    editxml   
#    Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
#    xslt = XML::XSLT.new()
#    xslt.xml = REXML::Document.new(@article.content)
#    xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    
#    @transformed = xslt.serve()
#  end

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
