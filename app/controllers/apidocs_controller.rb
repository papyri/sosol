class ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'SoSOL'
      key :description, 'SoSOL API'
      key :termsOfService, 'TODOCOMEFROMCONFIG'
      contact do
        key :name, 'TODOCOMEFROMCONFIG'
      end
      license do
        key :name, 'TODOCOMEFROMCOFING'
      end
    end
    tag do
      key :name, 'Identifier'
      key :description, 'Identifier operations'
    end
    key :host, Sosol::Application.config.api_base.sub(/https?:\/\//,'')
    key :basePath, '/api/v1'
    key :consumes, ['application/json']
    key :produces, ['application/json', 'application/xml']
    security_definition :sosol_auth do
      key :type, :oauth2
      key :authorizationUrl, "#{Sosol::Application.config.api_base}/oauth/authorize"
      key :flow, :accessCode
     key :tokenUrl, "#{Sosol::Application.config.api_base}/oauth/token"
      key :flow, :accessCode
      scopes do
        key 'write', 'modify identifiers in your account'
        key 'read', 'read your user details'
      end
    end
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Api::V1::ApiController,
    Api::V1::ItemsController,
    Identifier,
    User,
    Api::V1::ApiError,
    self,
  ].freeze


  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end

end
