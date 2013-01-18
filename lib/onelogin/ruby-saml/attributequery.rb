require "base64"
require "uuid"
require "zlib"
require "cgi"
require "rexml/document"
require "rexml/xpath"

module Onelogin
  module Saml
  include REXML
    class AttributeQuery
      def create(nameId, settings, params = {})
        request_doc = create_attribute_query_xml_doc(nameId,settings)

        request = ""
        request_doc.write(request)
        request
      end

      def create_attribute_query_xml_doc(a_nameid, settings)
        uuid = "_" + UUID.new.generate
        time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        # Create soap Envelope root element using REXML 
        request_doc = REXML::Document.new
        root = request_doc.add_element "soap11:Envelope", { "xmlns:soap11" => "http://schemas.xmlsoap.org/soap/envelope/"}
        body = root.add_element "soap11:Body", { "xmlns:soap11" => "http://schemas.xmlsoap.org/soap/envelope/"}
        query = body.add_element "samlp:AttributeQuery", { "xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol" }
        query.attributes['ID'] = uuid
        query.attributes['IssueInstant'] = time
        query.attributes['Version'] = "2.0"
        
        if settings.issuer != nil
          issuer = query.add_element "saml:Issuer", { "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion" }
          issuer.text = settings.issuer
        end
        subject = query.add_element "saml:Subject", { "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion" }
        nameid = subject.add_element "saml:NameID",  { 
          "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion",
          "Format" => settings.name_identifier_format }
        nameid.text = a_nameid 
        request_doc
      end

    end
  end
end
