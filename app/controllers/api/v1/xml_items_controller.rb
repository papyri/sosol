module Api::V1

  class XmlItemsController < ItemsController
    rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
    include Swagger::Blocks
 
    swagger_path "/xmlitems/{identifier_type}" do
      operation :post do
        key :description, 'Creates a new publication and identifier for a posted XML document'
        key :operationId, 'createXmlItem'
        key :tags, [ 'identifier' ]
        key :consumes, ['application/xml']
        parameter do 
          key :name, :identifier_type
          key :in, :path
          key :description, "identifier type"
          key :required, true
          key :type, :string
        end
        parameter do
          key :name, :content
          key :in, :body
          schema do
            key :xml, { }
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

    def create
      (response,code) = _api_item_create
      if (code != 200) 
        render_api_error(code,response) and return
      end
      @identifier = response
      respond_to do |format|
        format.json { render :json=> ApiHelper::build_identifier(@identifier) }
        format.xml { render :xml => "<item>#{id}</item>" } #legacy api
      end
    end

  end
end

