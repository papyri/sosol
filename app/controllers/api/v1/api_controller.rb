module Api::V1
  class ApiController < DmmApiController
    include Swagger::Blocks
    require 'uuid'

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

    swagger_path "/export_ro" do
      operation :get do
        key :description, 'Prototype of an API call to export a Research Object bundle of a user\'s publications. WIP'
        key :operationId, 'exportRo'
        key :tags, [ 'user' ]
        security do
          key :sosol_auth, ['read']
        end
        parameter do
          key :name, 'publication_id[]'
          key :in, :query
          key :description, "publication id(s) to export"
          key :required, true
          key :type, :array
          key :items, {  :type => :string }
        end
        response 200 do
          key :description, 'will eventually be a BagIt archive of a Research Object Bundle'
        end
        response :default do
          key :description, 'unexpected error'
          schema do 
            key :'$ref', :ApiError
          end
        end
      end
    end
    def export_ro
      manifest = {}
      manifest["@context"] = ["https://w3id.org/bundle/context"]
      manifest["@id"] = UUID.generate
      manifest["createdOn"] =  Time.new
      manifest["createdBy"] = { 
        "name" => @current_user.full_name,
        "uri" => "#{Sosol::Application.config.site_user_namespace}#{URI.escape(@current_user.name)}"
      }
      manifest['aggregates'] = []
      manifest['annotations'] = []
      annotations = {}
      params[:publication_id].each do |p|
        begin
          pub = Publication.find(p)
        rescue
          next
        end 
        pub.identifiers.each do |i|
          unless i.respond_to?(:as_ro)
            next
          end
          ro = i.as_ro
          manifest["aggregates"].concat(ro['aggregates'])
          annotations[i.id] = ro['annotations']
        end
      end    
      redirect_svc = "http://catalog.perseus.org/cite-collections/api/versions/redirect?format=json&version=REPLACE_VERSION"
      redirected = {}
      manifest['aggregates'].each do |a|
        if redirected[a['uri']]
          next
        end
        url = URI.parse(redirect_svc.sub(/REPLACE_VERSION/,a['uri']))
        response = Net::HTTP.start(url.host, url.port) do |http|
          http.send_request('GET',url.request_uri)
        end
        unless (response.code == '200')
          # to do handle error
        end
        redirect = JSON.parse(response.body.force_encoding("UTF-8"))
        if redirect && redirect.size > 0 
          new_uri = redirect[0]['version']
          redirected[a['uri']] = new_uri
          a['uri'] = new_uri
        end
      end
      annotations.each do |identifier,arr|
        item_api_url = url_for(:controller => 'items') + "/#{identifier}"
        arr.each do |a|
          a['about'].each_with_index do |u,i|
            redirected.each do |k,v|
              if u =~ /^#{k}:|$/
                a['about'][i]  = u.sub(k,v)
              end
            end
          end
          if (a['query']) 
            annotation_url = item_api_url + "?q=" + URI.escape(a['query'])
          else
            annotation_url = item_api_url
          end
          manifest['annotations'] << { 'about' => a['about'], 'content' => annotation_url, 'dc:format' => a['dc:format'] }
        end
      end
      render :json => manifest 
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
