module Api::V1
  class ApiController < DmmApiController
    include Swagger::Blocks
    def current_resource_owner
      User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

    skip_before_filter :authorize 
    before_filter only: [:user] do
      doorkeeper_authorize! :read
    end

    swagger_path "/user" do
      operation :get do
        key :description, 'Get current user info'
        key :operationId, 'getUserInfo'
        key :tags, [ 'user' ]
        security do
          key :sosol_auth, ['read']
        end
        response 201 do
          key :description, 'user info response'
          schema do
            key :'$ref' , :User
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

    def user
      ping
    end
  end
end
