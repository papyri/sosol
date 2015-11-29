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
        key :name, 'GPL 3.0'
      end
    end
    tag do
      key :name, 'Identifier'
      key :description, 'Identifier operations'
    end
    key :host, 'TODOCOMEFROMCONFIG'
    key :basePath, '/api'
    key :consumes, ['application/json', 'application/xml']
    key :produces, ['application/json', 'application/xml']
    security_definition :sosol_auth do
      key :type, :oauth2
      key :authorizationUrl, 'TODOCONTROLLERURLFORAUTHORIZE'
      key :flow, :accessCode
      key :tokenUrl, 'TODOCONTROLLERURLFORTOKEN'
      scopes do
        key 'write:identifiers', 'modify identifiers in your account'
        key 'read:identifiers', 'read your identifiers'
      end
    end
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Api::V1::ItemsController,
    Identifier,
    Api::V1::ApiErrorModel,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
