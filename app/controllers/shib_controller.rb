require 'ruby-saml'

class ShibController < ApplicationController

    def init
      request = Onelogin::Saml::Authrequest.new
      redirect_to(request.create(saml_settings))
    end

    def consume
      # TODO We should not skip conditions: this was to deal with time discrepancies -- in live environment
      # need to make sure time issues are resolved via appropriate means
      response          = Onelogin::Saml::Response.new(params[:SAMLResponse],{:skip_conditions => true})
      response.settings = saml_settings

      if response.is_valid?
        Rails.logger.debug("Valid Shib Response #{response}")
        att_request = Onelogin::Saml::AttributeQuery.new
        att_request = att_request.create(response.name_id,saml_settings,{})
        uri = URI.parse(saml_settings.idp_aqr_target_url)
        
        # TODO - these should be part of the saml settings
        cert = File.read(File.join("#{RAILS_ROOT}", 'data', 'certificates', 'perseus-sosol.crt'))
        key = File.read(File.join("#{RAILS_ROOT}", 'data', 'certificates', 'perseus-sosol.key'))
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
            headers = {'Content-Type' => 'text/xml; charset=utf-8'}
            http.cert = OpenSSL::X509::Certificate.new(cert)
            http.key = OpenSSL::PKey::RSA.new(key)
        http_response = http.send_request('POST',uri.request_uri,att_request,headers)
        if (http_response.code == '200')
          Rails.logger.info("AQ Response = #{http_response.body}")
          att_response = Onelogin::Saml::Response.new(http_response.body)
          @samlResponse = CGI.escapeHTML(http_response.body)

          # TODO use eppn value as identifer for sosol user, lookup account, create if doesn't exist
          #if att_response.is_valid? && user = current_account.users.find_by_identifier(response.eppn)
          #   authorize_success(user)
          #else
          #   authorize_failure(user)
          #end
        else
          Rails.logger.info("AQ Request failed: #{response.code}")
        end

        
      else
        Rails.logger.info("Invalid Shib Response #{response}")
      end
     
    end
    
    def metadata
      settings = Onelogin::Saml::Settings.new

      # TODO get all metadata from config
      # acs url should be the Apache https proxy for the environment 
      settings.assertion_consumer_service_url = "https://dev.alpheios.net/sosol/shib/consume"
      settings.issuer                         = "sosol.perseus.tufts.edu"
      settings.sp_cert                       = File.read(File.join("#{RAILS_ROOT}", 'data', 'certificates', 'perseus-sosol.crt'))
      meta = Onelogin::Saml::Metadata.new
      render :xml => meta.generate(settings)
    end


    private

    def saml_settings
      settings = Onelogin::Saml::Settings.new

      # TODO GET all metadata from config
      # acs url should be the Apache https proxy for the environment 
      settings.assertion_consumer_service_url = "https://dev.alpheios.net/sosol/shib/consume"
      
      # TODO will we use a WAYF service to get list of available IdPs?
      settings.idp_sso_target_url = "https://shibidp-test.uit.tufts.edu:8443/idp/profile/SAML2/Unsolicited/SSO?providerId=sosol.perseus.tufts.edu"
      settings.idp_aqr_target_url = "https://shibidp-test.uit.tufts.edu:8443/idp/profile/SAML2/SOAP/AttributeQuery?providerId=sosol.perseus.tufts.edu"

      # TODO should be request.host in production deployment
      settings.issuer                         = "sosol.perseus.tufts.edu"
      settings.idp_cert                       = File.read(File.join("#{RAILS_ROOT}", 'data', 'certificates', 'tuftstest.crt')) 
      # TODO this is depends upon the IdP
      settings.name_identifier_format         = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
      # Optional for most SAML IdPs
      settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      
      settings
    end

end
