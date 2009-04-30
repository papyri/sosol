class ArticlesController < ApplicationController
  layout 'site'
  
  # GET /publications
  # GET /publications.xml
  def index
    # @publications = Article.find(:all)
    @publications = []
    @branches = []
    if !@current_user.nil?
      @branches = @current_user.repository.branches
      @branches.delete("master")
      
      user_publications = Publication.find_all_by_user_id(@current_user.id)
      # probably not strictly necessary to intersect publications against
      # branches as this will eventually be enforced in the model
      @publications = user_publications.select do |publication|
        @branches.include?(publication.branch)
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @branches }
    end
  end
end