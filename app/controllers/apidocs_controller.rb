class ApidocsController < ActionController::Base
  include Swagger::Blocks

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Api::V1::ApiController,
    Api::V1::ItemsController,
    Api::V1::XmlItemsController,
    Api::V1::PublicationsController,
    Identifier,
    Publication,
    User,
    Api::V1::ApiError,
    self,
  ].freeze


  def index
    self.class.set_swagger_root(request.host,request.scheme,root_path,root_url)
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end

  def self.set_swagger_root(host,scheme,root_path,root_url)
    # TODO need to fix this before going to production
    # need a way to get access to the actual scheme when behind an apache
    # proxy -- maybe needs to be forwarded by Apache to tomcat in a header
    #if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'staging'
    #  root_url.sub!(/http:/,'https:')
    #end 
    swagger_root do
      key :swagger, '2.0'
      info do
        key :version, '1.0.0'
        key :title, 'SoSOL'
        key :description, 'SoSOL API'
        key :termsOfService, "#{root_url}api/v1/terms"
        contact do
          key :url, "#{root_url}api/v1/contact"
        end
        license do
          key :name, "#{root_url}api/v1/license"
        end
      end
      tag do
        key :name, 'Identifier'
        key :description, 'Identifier operations'
      end
      key :host, "#{host}"
      key :schemes, [scheme]
      key :basePath, "#{root_path}api/v1"
      key :consumes, ['application/json']
      key :produces, ['application/json', 'application/xml']
      security_definition :sosol_auth do
        key :type, :oauth2
        key :authorizationUrl, "#{root_url}oauth/authorize"
        key :flow, :accessCode
        key :tokenUrl, "#{root_url}oauth/token"
        key :flow, :accessCode
        scopes do
          key 'write', 'modify identifiers in your account'
          key 'read', 'read your user details'
        end
      end
    end
  end

end
