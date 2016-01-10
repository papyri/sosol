module Api::V1
  class ApiController < DmmApiController
    include Swagger::Blocks

    skip_before_filter :authorize 
    before_filter only: [:user] do
      doorkeeper_authorize! :read
    end

    before_filter do
      current_user
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
    private
    def current_user
        @current_user ||= User.find(doorkeeper_token[:resource_owner_id])
    end
  end
end
