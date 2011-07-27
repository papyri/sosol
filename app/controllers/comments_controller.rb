class CommentsController < ApplicationController
  before_filter :authorize
  
  # GET /comments
  # GET /comments.xml
  def index
    @comments = Comment.find(:all)
    
    #unescaping the stored comment because of possible special math symbols 𐅵𐅷𐅸 
    #character reference &#x10175; &#x10177; &#x10178; or javacode escape \ud800\udd75 \ud800\udd77 \ud800\udd78
    @comments.each do |nc|
      nc.comment = CGI.unescape(nc.comment)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET
  def ask_for
    #shows current comments and gives form for new comment
    @publication = Publication.find(params[:publication_id])
    @publication_id = @publication.origin.id
    
    @identifier = Identifier.find(params[:identifier_id])
    @identifier_id  = @identifier.origin.id
   
    @comments = Comment.find_all_by_publication_id(@publication_id, :order => 'created_at').reverse
    
    #unescaping the stored comment because of possible special math symbols 𐅵𐅷𐅸 - escaping HTML for display if there
    #character reference &#x10175; &#x10177; &#x10178; or javacode escape \ud800\udd75 \ud800\udd77 \ud800\udd78
    @comments.each do |nc|
      nc.comment = CGI.escapeHTML(CGI.unescape(nc.comment))
    end

  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = Comment.find(params[:id])
    #unescaping the stored comment because of possible special math symbols 𐅵𐅷𐅸 
    #character reference &#x10175; &#x10177; &#x10178; or javacode escape \ud800\udd75 \ud800\udd77 \ud800\udd78
    @comment.comment = CGI.unescape(@comment.comment)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = Comment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id])
    #unescaping the stored comment because of possible special math symbols 𐅵𐅷𐅸 
    #character reference &#x10175; &#x10177; &#x10178; or javacode escape \ud800\udd75 \ud800\udd77 \ud800\udd78
    @comment.comment = CGI.unescape(@comment.comment)
  end

  # POST /comments
  # POST /comments.xml
  def create
  
    @comment = Comment.new(params[:comment])
    
    #escaping the comment was the only way to get the DB to store special math symbols 𐅵𐅷𐅸 if there
    #character reference &#x10175; &#x10177; &#x10178; or javacode escape \ud800\udd75 \ud800\udd77 \ud800\udd78
    @comment.comment = CGI.escape(@comment.comment)
    
    @comment.user_id = @current_user.id
 #   if params[:reason] != nil
 #     @comment.reason = params[:reason]
 #   end
  
    respond_to do |format|
      if @comment.save
        flash[:notice] = 'Comment was successfully created.'
        
        #url will not work correctly without :id, however id is not used in ask_for, so we just use 1
        format.html { redirect_to :id => 1, :controller => "comments", :action => "ask_for", :publication_id => @comment.publication_id, :identifier_id => @comment.identifier.id, :method => "get" }
        #format.html { redirect_to(@comment) }
        #TODO redirect xml?
        format.xml  { render :xml => @comment, :status => :created, :location => @comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = Comment.find(params[:id])
    #escaping the comment was the only way to get the DB to store special math symbols 𐅵𐅷𐅸 if there
    #character reference &#x10175; &#x10177; &#x10178; or javacode escape \ud800\udd75 \ud800\udd77 \ud800\udd78 
    params[:comment][:comment] = CGI.escape(params[:comment][:comment])
    
    respond_to do |format|    
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { redirect_to(@comment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.xml  { head :ok }
    end
  end
end
