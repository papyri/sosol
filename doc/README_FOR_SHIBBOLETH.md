# Overview

The SoSOL code supports the ability to configure one or more Shibboleth/SAML2 Identity 
Providers as an alternative to OpenID for user identification and authentication.

A unique identifier is assigned to the SoSOL user by combining the IdP Issuer Entity Id
with the value of the NameID attribute asserted by the IdP for the user.

# Supported Profiles

The code currently supports the Shibboleth/SAML2 SSO and AttributeQueryProfiles.

See https://wiki.shibboleth.net/confluence/display/DEV/Supported+Protocols for more details.  

The SoSOL Shibboleth Service Provider code supports the following RelyingParty configuration:

    <rp:RelyingParty id="example.sosol.entityid"
      defaultSigningCredentialRef="IdPCredential"
      provider="https://example.idp.org/idp/shibboleth"
      defaultAuthenticationMethod="urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport">
      
      <rp:ProfileConfiguration xsi:type="saml:ShibbolethSSOProfile" 
          includeAttributeStatement="false"
          assertionLifetime="PT5M" 
          signResponses="conditional" 
          signAssertions="never"/>

        <rp:ProfileConfiguration xsi:type="saml:SAML1AttributeQueryProfile" 
          assertionLifetime="PT5M"
          signResponses="conditional" 
          signAssertions="never"/>          
          
        <rp:ProfileConfiguration xsi:type="saml:SAML1ArtifactResolutionProfile" 
          signResponses="conditional"
          signAssertions="never"/>

        <rp:ProfileConfiguration xsi:type="saml:SAML2SSOProfile" 
          includeAttributeStatement="false"
          assertionLifetime="PT5M" assertionProxyCount="0"
          signResponses="never" signAssertions="always"
          encryptAssertions="never" encryptNameIds="never"/>

        <rp:ProfileConfiguration xsi:type="saml:SAML2ECPProfile" 
           includeAttributeStatement="true"
           assertionLifetime="PT5M" assertionProxyCount="0"
           signResponses="never" signAssertions="always"
           encryptAssertions="conditional" encryptNameIds="never"/>

        <rp:ProfileConfiguration xsi:type="saml:SAML2AttributeQueryProfile"
            assertionLifetime="PT5M" assertionProxyCount="0"
            signResponses="conditional" signAssertions="always"
            encryptAssertions="never" encryptNameIds="never"/>

        <rp:ProfileConfiguration xsi:type="saml:SAML2ArtifactResolutionProfile"
            signResponses="never" signAssertions="never"
             encryptAssertions="conditional" encryptNameIds="never"/>

    </rp:RelyingParty>

# Limitations of the SoSOL SAM2 Service Provider Implementation

  * Currently does not support receipt of encrypted attributes.
  * Does not support the SAML2 Discovery Service Profile
  * Does not support federation metadata. Each IdentityProvider 
    relationship must be negotiated and configured separately. 

# Global Configuration
Global configuration settings which affect all IdP interactions are configured
in the shibboleth.yml file in the config directory. The available settings 
are described below (text in <> should be replaced as appropriate for the deployment environment):

    shibboleth:
        :allowed_clock_drift: <allowed time difference between IdP and SP in seconds>
        :issuer: <sosol deployment entity id> 
        :sp_cert: <file system path to SP public X509 certificate>
        :sp_private_key: <file system path to SP private X509 signing key>
        :assertion_consumer_service_url: "https://<base url for SosOl deployment>/shib/consume"


# IdP Configuration

The IdPs with which the SoSOL deployment can interact as a Service Provider are
configured in the shibboleth.yml file in the config directory.  The available settings 
are described below (text in <> should be replaced as appropriate for the deployment environment):

    shibboleth:    
        :idps:
          <idplookupkey>:
            :entity_id: <idp entity id>
            :display_name: <display name for IdP>
            :logo: <logo file for IdP>
            :idp_cert: <path to IdP public X509 certificate>
            :idp_sso_target_url: "https://<idp sso base url>/idp/profile/SAML2/Unsolicited/SSO?providerId=<sosol entity id>"
            :idp_aqr_target_url: "https://<idp aq base url>/idp/profile/SAML2/SOAP/AttributeQuery?providerId=<sosol entity id>"
            :name_identifier_format: <Name Identifier Format in AuthNResponse>
            :authn_context: <Required AuthN Context for the IdP>
            :attributes:
              :display_id: <IdP supplied attribute to display to user upon SoSOL id creation>        


# Environment Configuration

Unless the entire SoSOL deployment is going to be under SSL, set the following in the 
environment.rb to allow the session cookie to apply under ssl: 
    config.action_controller.session = {
        :httponly => false
      }
  
# Deployment Dependencies

* ruby_saml (currently in perseus_shibboleth branch - changes to be sent in pull request to ruby_saml owners)
* requres canonix 0.1.7 instead of xmlcanonicalizer (required for canonicalization with namespace instance prefixes)
* for some reason 0.1.7 breaks warble so must be manually included in war or deployment environment 
* openssl 0.7.7 (instead of 0.5.2)


