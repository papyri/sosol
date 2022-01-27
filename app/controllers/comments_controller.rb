# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authorize

  layout false
  # GET /comments
  # GET /comments.xml
  def index
    @comments = Comment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @comments }
    end
  end

  # GET
  # - shows current comments and gives form for new comment
  def ask_for
    @publication = Publication.find(params[:publication_id].to_s)
    @publication_id = @publication.origin.id

    @identifier = Identifier.find(params[:identifier_id].to_s)
    @identifier_id = @identifier.origin.id

    @comments = Comment.where(publication_id: @publication_id).order(created_at: :desc)
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = Comment.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = Comment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id].to_s)
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = Comment.new(comment_params)

    @comment.user_id = @current_user.id
    #   if params[:reason] != nil
    #     @comment.reason = params[:reason]
    #   end

    respond_to do |format|
      if @comment.save
        flash[:notice] = 'Comment was successfully created.'

        # url will not work correctly without :id, however id is not used in ask_for, so we just use 1
        format.html do
          redirect_to id: 1, controller: 'comments', action: 'ask_for', publication_id: @comment.publication_id,
                      identifier_id: @comment.identifier.id, method: 'get'
        end
        # format.html { redirect_to(@comment) }
        # TODO redirect xml?
        format.xml  { render xml: @comment, status: :created, location: @comment }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = Comment.find(params[:id].to_s)

    respond_to do |format|
      if params[:comment].present? && params[:comment].is_a?(Hash) && @comment.update(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { redirect_to(@comment) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = Comment.find(params[:id].to_s)
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.xml  { head :ok }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:comment, :identifier_id, :publication_id, :reason)
  end
end
