module Api::V1

  class ApiErrorModel
    include Swagger::Blocks
    swagger_schema :ErrorModel do
      key :required, [:code, :message]
      property :code do
        key :type, :integer
        key :format, :int32
      end
      property :message do
        key :type, :string
      end
    end
  end
    
  class ItemsController < ApiController
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
            key :'$ref', :ApiErrorModel
          end
        end
      end
    end

    def create
      parsed_params = JSON.parse(request.raw_post.force_encoding("UTF-8"))
      params["identifier_type"] = parsed_params["type"]
      params["raw_post"] = parsed_params["content"]
      api_item_create
    end

  end
end
