require "xml_security"
require "time"
require "nokogiri"

# Only supports SAML 2.0
module Onelogin
  module Saml

    class Response
      ASSERTION = "urn:oasis:names:tc:SAML:2.0:assertion"
      PROTOCOL  = "urn:oasis:names:tc:SAML:2.0:protocol"
      DSIG      = "http://www.w3.org/2000/09/xmldsig#"
      SOAP      = "http://schemas.xmlsoap.org/soap/envelope/"

      attr_accessor :options, :response, :document, :settings

      def initialize(response, options = {})
        raise ArgumentError.new("Response cannot be nil") if response.nil?
        self.options  = options
        self.response = response
        

        # TODO AttributeQuery Response handling should probably go into a subclass of response
        if (options[:is_aq_response])
          begin
           envelope = REXML::Document.new(response)
           wrapped = REXML::XPath.first(envelope,'o:Envelope/o:Body/p:Response', {'p' => PROTOCOL, 'o' => SOAP})
           self.document = XMLSecurity::SignedDocument.new(wrapped.to_s)
          rescue REXML::ParseException => e
            Rails.logger.debug("Failed to parse AQ response ",e)
            self.document = XMLSecurity::SignedDocument.new(Base64.decode64(response))
          end
        else
          begin
            self.document = XMLSecurity::SignedDocument.new(Base64.decode64(response))
          rescue REXML::ParseException => e
            if response =~ /</
              self.document = XMLSecurity::SignedDocument.new(response)
            else
              raise e
            end
          end
        end
      end

      def is_valid?
        validate
      end

      def validate!
        validate(false)
      end

      # The value of the user identifier as designated by the initialization request response
      def name_id
        @name_id ||= begin
          node = REXML::XPath.first(document, "/p:Response/a:Assertion[@ID='#{document.signed_element_id}']/a:Subject/a:NameID", { "p" => PROTOCOL, "a" => ASSERTION })
          node ||=  REXML::XPath.first(document, "/p:Response[@ID='#{document.signed_element_id}']/a:Assertion/a:Subject/a:NameID", { "p" => PROTOCOL, "a" => ASSERTION })
          node.nil? ? nil : node.text
        end
      end
      
      # returns the scoped value of the eduPersonTargetedId attribute 
      # TODO this should go into an AttributeQuery response subclass
      # and be generalized to support any scoped attribute
      def scoped_targeted_id 
        @name_id ||= begin
          node = REXML::XPath.first(document,"/p:Response/a:Assertion/a:AttributeStatement/a:Attribute[@Name='urn:oid:1.3.6.1.4.1.5923.1.1.1.10']/a:AttributeValue/a:NameID", { "p" => PROTOCOL, "a" => ASSERTION })
          node.nil? ? nil : node.attributes["NameQualifier"]+"/" + node.text
        end
      end 
      
      # A hash of alle the attributes with the response. Assuming there is only one value for each key
      def attributes
        @attr_statements ||= begin
          result = {}

          stmt_element = REXML::XPath.first(document, "/p:Response/a:Assertion/a:AttributeStatement", { "p" => PROTOCOL, "a" => ASSERTION })
          return {} if stmt_element.nil?

          stmt_element.elements.each do |attr_element|
            name  = attr_element.attributes["Name"]
            value = attr_element.elements.first.text

            result[name] = value
          end

          result.keys.each do |key|
            result[key.intern] = result[key]
          end

          result
        end
      end

      # When this user session should expire at latest
      def session_expires_at
        @expires_at ||= begin
          node = REXML::XPath.first(document, "/p:Response/a:Assertion/a:AuthnStatement", { "p" => PROTOCOL, "a" => ASSERTION })
          parse_time(node, "SessionNotOnOrAfter")
        end
      end
      
      # Checks the status of the response for a "Success" code
      def success?
        @status_code ||= begin
          node = REXML::XPath.first(document, "/p:Response/p:Status/p:StatusCode", { "p" => PROTOCOL, "a" => ASSERTION })
          node.attributes["Value"] == "urn:oasis:names:tc:SAML:2.0:status:Success"
        end
      end

      # Conditions (if any) for the assertion to run
      def conditions
        @conditions ||= begin
          REXML::XPath.first(document, "/p:Response/a:Assertion[@ID='#{document.signed_element_id}']/a:Conditions", { "p" => PROTOCOL, "a" => ASSERTION })
        end
      end
      
      def not_before
        @not_before ||= parse_time(conditions, "NotBefore")
      end

      def not_on_or_after
        @not_on_or_after ||= parse_time(conditions, "NotOnOrAfter")
      end

      def issuer
        @issuer ||= begin
          node = REXML::XPath.first(document, "/p:Response/a:Issuer", { "p" => PROTOCOL, "a" => ASSERTION })
          node ||= REXML::XPath.first(document, "/p:Response/a:Assertion/a:Issuer", { "p" => PROTOCOL, "a" => ASSERTION })
          node.nil? ? nil : node.text
        end
      end

      private

      def validation_error(message)
        raise ValidationError.new(message)
      end

      def validate(soft = true)
        valid_structure = validate_structure(soft)
        valid_response_state = validate_response_state(soft)
        valid_conditions = validate_conditions(soft)
        valid_doc = document.validate(get_fingerprint, soft)
        valid_structure && Rails.logger.info("Valid Structure #{valid_structure}")
        Rails.logger.debug("Valid Response State #{valid_response_state}")
        Rails.logger.debug("Valid Conditions #{valid_conditions}")
        Rails.logger.debug("Valid Doc #{valid_doc}")
        Rails.logger.debug("Success #{success?}")
        valid_structure      &&
        valid_response_state &&
        valid_conditions     &&
        valid_doc && 
        success?
      end

      def validate_structure(soft = true)
        Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'schemas'))) do
          @schema = Nokogiri::XML::Schema(IO.read('saml20protocol_schema.xsd'))
          @xml = Nokogiri::XML(self.document.to_s)
        end
        status = false
        if soft
          status = @schema.validate(@xml).map{ return false }
        else
          status = @schema.validate(@xml).map{ |error| raise(Exception.new("#{error.message}\n\n#{@xml.to_s}")) }
        end
        return status
      end

      def validate_response_state(soft = true)
        if response.empty?
          return soft ? false : validation_error("Blank response")
        end

        if settings.nil?
          return soft ? false : validation_error("No settings on response")
        end

        if settings.idp_cert_fingerprint.nil? && settings.idp_cert.nil?
          return soft ? false : validation_error("No fingerprint or certificate on settings")
        end

        true
      end

      def get_fingerprint
        if settings.idp_cert
          cert = OpenSSL::X509::Certificate.new(settings.idp_cert)
          Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(":")
        else
          settings.idp_cert_fingerprint
        end
      end

      def validate_conditions(soft = true)
        return true if conditions.nil?
        return true if options[:skip_conditions]

        now = Time.now.utc
        Rails.logger.debug("Now: #{now}")
        Rails.logger.debug("Now with drift: #{now + (options[:allowed_clock_drift] || 0)}")
        Rails.logger.debug("Not Before: #{not_before}")
        Rails.logger.debug("Not After: #{not_on_or_after}")

        if not_before && (now + (options[:allowed_clock_drift] || 0)) < not_before
          return soft ? false : validation_error("Current time is earlier than NotBefore condition")
        end

        if not_on_or_after && now >= not_on_or_after
          return soft ? false : validation_error("Current time is on or after NotOnOrAfter condition")
        end

        true
      end

      def parse_time(node, attribute)
        if node && node.attributes[attribute]
          Time.parse(node.attributes[attribute])
        end
      end
    end
  end
end
