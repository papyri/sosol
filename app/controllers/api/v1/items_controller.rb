module Api::V1

  class ItemsController < ApiController
    rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
    include Swagger::Blocks
 
    skip_before_filter :authorize 
    before_filter only: [:create, :update, :destroy] do
      doorkeeper_authorize! :write
    end

    swagger_path "/items" do
      operation :post do
        key :description, 'Creates a new publication for the supplied data identifier type'
        key :operationId, 'createByIdentifierType'
        key :tags, [ 'identifier' ]
        parameter do 
          key :name, :content
          key :in, :body
          schema do
            key :'$ref', :Identifier
          end
        end
        security do
          key :sosol_auth, ['write']
        end
        response 201 do
          key :description, 'item create response'
          schema do
            key :'$ref' , :Identifier
          end
        end
        response :default do
          key :description, 'unexpected error'
          schema do 
            key :'$ref', :ApiError
          end
        end
      end
    end
    swagger_path "/items/{id}" do
      operation :get do 
        key :description, 'get the identifier'
        key :operationId, 'getIdentifier'
        key :tags, [ 'identifier' ]
        parameter do
          key :name, :id
          key :in, :path
          key :description, "item id"
          key :required, true
          key :type, :int64
        end
        parameter do
          key :name, :q
          key :in, :query
          key :description, "item query"
          key :required, false
          key :type, :string
        end
        response 200 do
          key :description, 'item get response'
          schema do
            key :'$ref' , :Identifier
          end
        end
        response 404 do
          key :description, 'Not Found'
          schema do 
            key :'$ref', :ApiError
          end
        end
        response 405 do
          key :description, 'Invalid Input'
          schema do 
            key :'$ref', :ApiError
          end
        end
      end
    end

    def create
      parsed_params = JSON.parse(request.raw_post.force_encoding("UTF-8"))
      params["identifier_type"] = parsed_params["type"]
      params["raw_post"] = URI.unescape(parsed_params["content"])
      if (parsed_params["publication_community_name"])
        @community = Community.find_by_name(parsed_params["publication_community_name"])
        if @community.nil?
          render_api_error(405,"Invalid Community #{parsed_params['publication_community_name']}") and return
        end   
      end
      (response,code) = _api_item_create
      if (code != 200) 
        render_api_error(code,response) and return
      end
      @identifier = response
      respond_to do |format|
        format.json { render :json=> build_item }
        format.xml { render :xml => "<item>#{id}</item>" } #legacy api
      end
    end

    def show
      @identifier = Identifier.find(params[:id])
      begin
        # TODO need to follow best practices on retrieiving partial items
        content = @identifier.api_get(params[:q]) 
      rescue Exception => e 
        render_api_error(405,e.message) and return
      end
      respond_to do |format|
        format.json { render :json => build_item(content) }
        format.xml { render :xml => content } # legacy api returns the content of object
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
      response = Api::V1::ApiError.new(code,message)
      respond_to do |format|
         format.json { render :json => response, :status => code }
         format.xml { render :xml => response, :status => code }
       end    
    end

    def build_item(content=nil)
      item = { }
      item[:id] = @identifier.id
      item[:type] = @identifier.type
      item[:publication] = @identifier.publication.id
      item[:collection] = @identifier.collection
      item[:publication_community_name] = @identifier.publication.community.friendly_name
      item[:content] = content.nil? ? @identifier.content : content
      item
    end
  end
end

