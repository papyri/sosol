module Api::V1

  class PublicationsController < ApiController
    rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
    include Swagger::Blocks
 
    skip_before_filter :authorize 
    before_filter only: [:submit, :destroy] do
      doorkeeper_authorize! :write
    end
    before_filter :publication_ownership_guard, :only => [:submit]

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

    def submit
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
          render :text => "", :status => 200
        else
          #cleanup comment that was inserted before submit completed that is no longer valid because of submit error
          cleanup_id = Comment.find(:last, :conditions => {:publication_id => params[:id].to_s, :reason => "submit", :user_id => @current_user.id } )
          Comment.destroy(cleanup_id)
          render_api_error("500",error_text)
        end
      end
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
      @publication ||= Publication.find(params[:publication_id].to_s, :lock => true)
      if ! @publication.mutable_by?(@current_user)
        return render_api_error('401','Operation not permitted.')
      end
      Rails.logger.info("Mutable by #{@current_user.inspect}")
    end

    def expire_api_item_cache(a_identifier_type,a_id)
      expire_fragment(:controller => 'dmm_api',
                      :action => 'api_item_get', 
                      :id => a_id,
                      :identifier_type => a_identifier_type)
    end
  end
end

