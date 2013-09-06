ruby_saml from
- requres canonix 0.1.7 instead of xmlcanonicalizer (required for canonicalization with namespace instance prefixes)
 -- but for some reason 0.1.7 breaks warble 
- requires openssl 0.7.7 (instead of 0.5.2)


Include supported profile details

Note that 

  config.action_controller.session = {
    :httponly => false
  }
  
  must be set in environment.rb