module Api::V1
  class ApiController < DmmApiController
    include Swagger::Blocks

    skip_before_filter :verify_authenticity_token #don't invalidate any existing browser session
    skip_before_filter :authorize  # skip regular authentication routes
    skip_before_filter :update_cookie # skip old api cookie handling
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

    def terms
      if (Sosol::Application.config.respond_to?(:site_api_terms)) 
         begin
           file_path = File.join(Rails.root,Sosol::Application.config.site_api_terms)
           template = ERB.new(File.new(file_path).read, nil, '-')
           @terms = template.result(binding).html_safe
         rescue Exception => e
           @terms = Sosol::Application.config.site_api_terms
         end
      else
        @terms = ''
      end
    end

    def license
      # if we don't have a license, assume it's the same as terms of service
      if (Sosol::Application.config.respond_to?(:site_api_license)) 
        @license = Sosol::Application.config.site_api_license
      elsif (Sosol::Application.config.respond_to?(:site_api_terms)) 
         begin
           file_path = File.join(Rails.root,Sosol::Application.config.site_api_terms)
           template = ERB.new(File.new(file_path).read, nil, '-')
           @license = template.result(binding).html_safe
         rescue Exception => e
           @license = Sosol::Application.config.site_api_terms
         end
      else
        @license = ''
      end
    end

    def contact
      @name = Sosol::Application.config.respond_to?(:site_api_contact_name) ? Sosol::Application.config.site_api_contact_name : ""
      @email = Sosol::Application.config.respond_to?(:site_api_contact_email) ? Sosol::Application.config.site_api_contact_email : ""
    end

    private
    def current_user
        if doorkeeper_token
          @current_user = User.find(doorkeeper_token[:resource_owner_id])
        end
    end
  end

  class ApiError
    include Swagger::Blocks
    swagger_schema :ApiError do
      key :required, [:code, :message]
      property :code do
        key :type, :integer
        key :format, :int32
      end
      property :message do
        key :type, :string
      end
    end

    attr_accessor :code, :message

    def initialize(code, message)
      @code = code
      @message = message
    end

    def to_str
      "<error code=\"#{code}\" message=\"#{message}\"/>"
    end
  end

end
