require 'ruby-saml'

class ShibController < ApplicationController
   
    protect_from_forgery :except => [:consume, :signin]
    
    def get_config
      unless defined? @shib_config
        @shib_config = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config shibboleth.yml})).read).result)[Rails.env][:shibboleth]
      end
      return @shib_config
    end
    
    def signin
      idp = params[:idp]
      unless (idp)
        flash[:error] = "No IdP Specified"
        redirect_to :controller => "signin", :action => "index"
        return 
      end
      request = Onelogin::Saml::Authrequest.new
      redirect_to(request.create(saml_settings(idp)))
    end

    def consume
      
      if params[:SAMLResponse].nil?
        flash[:error] = "SAMLResponse is missing."
        redirect_to :controller => "signin", :action => "index"
        return 
      end 
      
      get_config
      # allowed_clock_drift is configured in seconds - allows for slight mismatch on time
      # between sp and idp servers
      allowed_clock_drift = @shib_config[:allowed_clock_drift] || 0
      response          = Onelogin::Saml::Response.new(params[:SAMLResponse],{:allowed_clock_drift => allowed_clock_drift})
      issuer = response.issuer
      
      # lookup the code for the idp using the entity_id for the issuer of the AuthResponse
      idp_matches = @shib_config[:idps].collect { |k,v|
        if (@shib_config[:idps][k][:entity_id] = issuer)
          k
        else
          nil
        end 
      }.compact
      
      # we must recognize the idp or we can't do anything
      if (idp_matches.length > 0) 
        idp = idp_matches[0]  
        response.settings = saml_settings(idp)
        
        # verify the validity of the AuthResponse
        if idp && response.is_valid?
          
          # TODO we should test first to see if the response contained any unencrypted
          # attributes before proceeding with the AttributeQuery request
          # this could all move to its own method too
          att_request = Onelogin::Saml::AttributeQuery.new
          att_request = att_request.create(response.name_id,response.settings,{})
          uri = URI.parse(response.settings.idp_aqr_target_url)
          
          cert = File.read(@shib_config[:idps][idp][:sp_cert])
          key = File.read(@shib_config[:sp_private_key])
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          headers = {'Content-Type' => 'text/xml; charset=utf-8'}
          http.cert = OpenSSL::X509::Certificate.new(cert)
          http.key = OpenSSL::PKey::RSA.new(key)
          http_response = http.send_request('POST',uri.request_uri,att_request,headers)
          
          # check the response to the AttributeQuery request
          # TODO we probably should make the attribute query response handling into a 
          # separate class in the one login lib and allow for more general retrieval of
          # scoped attribute values
          if (http_response.code == '200')
            att_response = Onelogin::Saml::Response.new(http_response.body,{:allowed_clock_drift => allowed_clock_drift, :is_aq_response => true})
            att_response.settings = saml_settings(idp)
            begin 
              if att_response.is_valid? && att_response.scoped_targeted_id
                user_identifier = UserIdentifier.find_by_identifier(att_response.scoped_targeted_id)
    
                if user_identifier
                  # User Identifier exists, login and redirect to index
                  user = user_identifier.user
                  session[:user_id] = user.id
                  if !session[:entry_url].blank?
                    redirect_to session[:entry_url]
                    session[:entry_url] = nil
                    return
                  else
                    redirect_to :controller => "user", :action => "dashboard"
                    return
                  end
                else 
                  # first login with this identifier let the user supply their details
                  session[:identifier] = att_response.scoped_targeted_id
                  @display_id = get_displayid(att_response.attributes,idp) || session[:identifier]
                  @email = guess_email(att_response.attributes, idp)
                  @name = guess_nickname(att_response.attributes, idp)
                  @full_name = guess_fullname(att_response.attributes, idp)
                end
              else # Invalid AQ Response or no scoped targed id
                Rails.logger.debug("AQ Response invalid: #{att_response.attributes.inspect}")
                flash[:error] = "SAML AttributeQuery returned an invalid response."
                redirect_to :controller => "signin", :action => "index"
              end
            rescue Exception => e # error caught checking validity of AQ Response
                Rails.logger.error("AQ Response invalid - caught exception", e)
                raise e
                flash[:error] = "SAML AttributeQuery returned an invalid response."
                redirect_to :controller => "signin", :action => "index"
            end
          else # end test on http_response code of attribute query request
            Rails.logger.debug("AQ Request failed: #{http_response.code}")
            flash[:error] = "SAML AttributeQuery Failed."
            redirect_to :controller => "signin", :action => "index"
          end
        else # invalid AuthResponse 
          Rails.logger.debug("Invalid Shib Response #{response}")
          flash[:error] = "SAML Authentication Failed."
          redirect_to :controller => "signin", :action => "index"
        end        
      else # end lookup test on idp issuer entity id
        Rails.logger.debug("Invalid Shib Response #{response}")
        flash[:error] = "SAML Authentication Failed."
        redirect_to :controller => "signin", :action => "index"
      end
     
    end
    
    def metadata
      idp = params[:idp]
      unless (idp)
        flash[:error] = "No IdP Specified"
        redirect_to :controller => "signin", :action => "index"
        return 
      end
      get_config
  
      settings = Onelogin::Saml::Settings.new
      settings.assertion_consumer_service_url = @shib_config[:assertion_consumer_service_url]
      settings.issuer                         = @shib_config[:issuer]
      # check to be sure the issuer isn't different for this IdP
      if (@shib_config[:idps][idp][:issuer])
        settings.issuer = @shib_config[:idps][idp][:issuer]
      end
      settings.sp_cert                       = File.read(@shib_config[:idps][idp][:sp_cert])
      meta = Onelogin::Saml::Metadata.new
      render :xml => meta.generate(settings)
    end
    
    # copied verbatim from the rpx_controller
    def create_submit
      identifier = session[:identifier]
      @name = params[:new_user][:name]
      @email = params[:new_user][:email]
      @full_name = params[:new_user][:full_name]
  
      if @name.empty?
        flash.now[:error] = "Nickname must not be empty"
        render :action => "shib_consume"
        return
      end
  
      begin
        user = User.create(:name => @name, :email => @email, :full_name => @full_name)
        #this save to execute validates_uniqueness_of :name so not continue with duplicate
        user.save!
      rescue ActiveRecord::RecordInvalid => e
        flash.now[:error] = "Nickname not available"
        render :action => "shib_consume"
        return
      end
  
      begin
        # If for any reason the Shib association step fails, we want to
        # be sure to recover from it and roll back any changes made up
        # to this point.  Otherwise, the user account will have been
        # created with no identifier associated with it.
        user.user_identifiers << UserIdentifier.create(:identifier => identifier)
        user.save!
        rescue Exception => e
          user.destroy
          flash.now[:error] = "An error occurred when attempting to create your account; try again. #{e.inspect}"
          render :action => "shib_consume"
          return
      end
  
      session[:user_id] = user.id
      session[:identifier] = nil
      
      if !session[:entry_url].blank?
        redirect_to session[:entry_url]
        session[:entry_url] = nil
        return
      else
        redirect_to :controller => "welcome", :action => "index"
      end
    end


    private

    def saml_settings(a_idp)
      get_config
      settings = Onelogin::Saml::Settings.new
      idp_settings = @shib_config[:idps][a_idp]

      # TODO GET all metadata from config
      # acs url should be the Apache https proxy for the environment 
      settings.assertion_consumer_service_url = @shib_config[:assertion_consumer_service_url]
      
      # TODO will we use a WAYF service to get list of available IdPs?
      settings.idp_sso_target_url = idp_settings[:idp_sso_target_url] 
      settings.idp_aqr_target_url = idp_settings[:idp_aqr_target_url]

      settings.issuer                         = @shib_config[:issuer]
      settings.idp_cert                       = File.read(idp_settings[:idp_cert]) 
      # TODO this is depends upon the IdP
      settings.name_identifier_format         = idp_settings[:name_identifier_format]
      # Optional for most SAML IdPs
      settings.authn_context = idp_settings[:authn_context]
      
      settings
    end

    def get_displayid(data,idp)
      if data[@shib_config[:idps][idp][:attributes][:display_id]]
        return data[@shib_config[:idps][idp][:attributes][:display_id]]
      end
      # There wasn't anything, so let the user enter a nickname
      return ''
    end
          
    def guess_nickname(data,idp)
      if data[@shib_config[:idps][idp][:attributes][:nickname]]
        return data[@shib_config[:idps][idp][:attributes][:nickname]]
      end
      # There wasn't anything, so let the user enter a nickname
      return ''
    end
    
    def guess_fullname(data,idp)
      if data[@shib_config[:idps][idp][:attributes][:fullname]]
        return data[@shib_config[:idps][idp][:attributes][:fullname]]
      end
      # There wasn't anything, so let the user enter a nickname
      return ''
    end
    
    def guess_email(data,idp)
      if data[@shib_config[:idps][idp][:attributes][:email]]
        return data[@shib_config[:idps][idp][:attributes][:email]]
      end
      # There wasn't anything, so let the user enter a nickname
      return ''
    end

end
