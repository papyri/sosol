= Perseids Development Environment 

== Prerequisites 

* follow instructions in README_FOR_APP
* install eXist 1.4.x with Alpheios CTS API code
    * See http://alpheios.net/content/alpheios-cts-api and follow instructions for Installation from Source to make sure you get the latest code.
    * this is used for extraction/merging of passage ranges in texts - really it doesn't require a database just an XQuery engine - prototype approach was just to use eXist because I had code that worked in it already        
* config config/environments/perseus_developmernt.rb to config/environments/development.rb
    * set `EXIST_STANDALONE_URL` to the path to your eXist installation
* copy config/perseus_environment.rb to config/environment.rb
    * `EXTERNAL_CTS_REPOS` can be set to the URI for an external CTS API from which to 
       retrieve data for annotation. In the Perseids environment this is currently a separate 
       installation of the Alpheios eXist CTS API with selected texts from the Perseus canonical text repository. Eventually if and when we have a fully working Perseus 5 CTS API this would be pointed at that,
       but could also reference other non Perseus repos.  More thought and work is needed here.
    * settings which need further thought and possibly code rework:
        * SITE_USER_NAMESPACE - this is intended to be the base uri for users on the platform
        * SITE_OAC_NAMESPACE - this is intended to be the base uri for new OAC annotations
        * SITE_CITE_COLLECTION_NAMESPACE - this is intended to be the base uri for new CITE objects
* To enable Shibboleth Authentication see README_FOR_SHIBBOLETH.md - see Bridget for security certificates and settings
  we still need to figure out the best way to store these securely
* clone a bare copy of the Perseids canonical git repo from the sosol.perseids.org server (it's in /usr/local/gitrepos/canonical.git)
    * Need to figure out how to integrate this with the PerseusDL canonical repo and to protect student data
* Install tools and update paths in config/tools.yml
    * Alpheios treebank editor - easiest for now is for this to reside in the same eXist instance
      as the EXIST_STANDALONE_URL instance. See http://alpheios.net/content/installation-alpheios-treebank-editor for installation
      instructions -- again best to install from source for now.
    * cite image service -- see https://bitbucket.org/neelsmith/sparqlimg
        * Current gets defined in both tools.yml and in meta element in app/views/layouts/perseus.haml - should only
          be in tools.yml 
    * ICT Tool -- see https://bitbucket.org/Eumaeus/hmt-ict2
        * Note location of this tool is currently defined in meta element in app/views/layouts/perseus.haml 
          needs to move to tools.yml

    
== NOTES FOR TOMCAT WAR DEPLOYMENT 

* must gem install jruby-jars-1.6.7 and jruby-rack-1.0.10
* WEB-INF/lib needs to include both jruby-jars-1.6.4 jruby-core-1.6.4 and jruby-jars-1.6.7 jruby-core-1.6.7
* must not have any other jruby-rack version installed in WEB-INF/lib
