module Api::V1

  class PublicationsController < ApiController
    rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
    include Swagger::Blocks
 
    skip_before_filter :authorize 
    before_filter only: [:submit, :update, :destroy] do
      doorkeeper_authorize! :write
    end
    before_filter :publication_ownership_guard, :only => [:submit, :update]

    swagger_path "/publications/{id}" do
      operation :get do
        key :description, 'Gets a publication and its identifiers'
        key :operationId, 'getPublication'
        key :tags, [ 'publication' ]
        parameter do 
          key :name, :id
          key :in, :path
          key :description, "publication id"
          key :required, true
          key :type, :integer
        end
        response 200 do
          key :description, 'publication submit response'
        end
        response :default do
          key :description, 'unexpected error'
          schema do 
            key :'$ref', :ApiError
          end
        end
      end
      operation :put do
        key :description, "Updates a publication"
        key :operationId, 'updatePublication'
        key :tags, [ 'publication' ]
        parameter do 
          key :name, :id
          key :in, :path
          key :description, "publication id"
          key :required, true
          key :type, :integer
        end
        parameter do 
          key :name, :content
          key :in, :body
          schema do
            key :'$ref', :Publication
          end
        end
        security do
          key :sosol_auth, ['write']
        end
        response 200 do
          key :description, 'publication submit response'
        end
        response :default do
          key :description, 'unexpected error'
          schema do 
            key :'$ref', :ApiError
          end
        end
      end
    end

    swagger_path "/publications/{id}/submit" do
      operation :post do
        key :description, 'Submits a publication'
        key :operationId, 'submitPublication'
        key :tags, [ 'publication' ]
        parameter do
          key :name, :id
          key :in, :path
          key :description, "publication id"
          key :required, true
          key :type, :integer
        end
        parameter do 
          key :name, :comment
          key :in, :query
          key :description, "submit comment"
          key :required, false
          key :type, :string
        end
        security do
          key :sosol_auth, ['write']
        end
        response 200 do
          key :description, 'publication submit response'
        end
        response :default do
          key :description, 'unexpected error'
          schema do 
            key :'$ref', :ApiError
          end
        end
      end
    end

    def show
      begin
      	@publication = Publication.find(params[:id].to_s, :lock => true)
        identifiers = @publication.identifiers.collect do |i|
            ApiHelper::build_identifier(i)
        end
        render :json => { :id => @publication.id, :community_name => @publication.community.nil? ? '' : @publication.community.name, :identifiers => identifiers }, :status => 200
      rescue Exception => e
        render_api_error(500,e.message)
      end
    end

    def submit
      begin
        @publication.with_lock do
          if @publication.status != 'editing' && @publication.status != 'new'
            render_api_error("405","Only publications in editing or new status be submitted via the api") and return
          end
          if @publication.community_id.nil?
            render_api_error("405","Only publications already assigned to a community may be submitted via the api") and return
          end
          unless @current_user.community_memberships.include?(@publication.community) || (@publication.community.allows_self_signup? && @publication.community.add_member(@current_user.id))
            render_api_error("401","Api User Not Authorized for this Community") and return
          end
          @comment = Comment.new( {:publication_id => params[:id].to_s, :comment => params[:comment].to_s, :reason => "submit", :user_id => @current_user.id } )
          @comment.save
          error_text, identifier_for_comment = @publication.submit
          if error_text == ""
            #update comment with git hash when successfully submitted
            @comment.git_hash = @publication.recent_submit_sha
            @comment.identifier_id = identifier_for_comment
            @comment.save
            render :text => "", :status => 200 and return
          else
            #cleanup comment that was inserted before submit completed that is no longer valid because of submit error
            cleanup_id = Comment.find(:last, :conditions => {:publication_id => params[:id].to_s, :reason => "submit", :user_id => @current_user.id } )
            Comment.destroy(cleanup_id)
            render_api_error(500,error_text) and return
          end
        end
      rescue Exception => e
        render_api_error(500,e.message)
      end
    end

    def update
      @publication.with_lock do
        if @publication.status != 'editing' && @publication.status != 'new'
          render_api_error(405,"Only publications in editing or new status be submitted via the api") and return
        end
        if (params["community_name"])
          @community = Community.find_by_name(params["community_name"])
          if @community.nil?
            render_api_error(405,"Invalid Community #{params['publication_community_name']}") and return
          end
          begin
            @publication.community = @community
            if @publication.community_can_be_assigned?
              @publication.save!
            else
              render_api_error(405, "Invalid community") and return
            end
          rescue Exception => e
            render_api_error(405,e.message) and return
          end
        end   
      end
      render :json => { :id => @publication.id, :community_name => @community.name }, :status => 200
    end

    private
    def record_not_found
      respond_to do |format|
        format.json { render :json => Api::V1::ApiError.new(404,'Not Found'), :status => 404 }
        format.xml { render :xml => Api::V1::ApiError.new(404,'Not Found'), :status => 404 }
      end
    end

    def render_api_error(code,message)
      response = ApiError.new(code,message)
      respond_to do |format|
         format.json { render :json => response, :status => code }
         format.xml { render :xml => response, :status => code }
       end    
    end

    def publication_ownership_guard
      @publication ||= Publication.find(params[:id].to_s, :lock => true)
      if ! @publication.mutable_by?(@current_user)
        return render_api_error('401','Operation not permitted.')
      end
    end

  end
end

