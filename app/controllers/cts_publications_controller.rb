class CtsPublicationsController < PublicationsController
  layout SITE_LAYOUT
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
  require 'jruby_xml'  
  
  ## Create/Update a CTS Publication from a linked URN
  def create_from_linked_urn
    if (params[:urn].blank? || params[:collection].blank?)
      flash[:error] = 'You must specify a URN and a Collection.'
      redirect_to dashboard_url
      return
    end
    
    urnObj = CTS::CTSLib.urnObj(params[:urn].to_s)
    sourceRepo = params[:src]
    sourceCollection = params[:collection]
   
    # get the Parent version URN and publication type
    versionUrn = urnObj.getUrnWithoutPassage()
    
    # if the version Urn is the same as the supplied urn then we don't have a citation specified
    citationUrn = (versionUrn == params[:urn]) ? nil :  params[:urn]
    
    pubtype = params[:pubtype] || CTS::CTSLib.versionTypeForUrn(sourceCollection,versionUrn)
    if pubtype.nil?
      flash[:error] = "No publication found for #{params[:urn]} in #{sourceCollection} inventory."
      redirect_to dashboard_url
      return
    end
    
    versionIdentifier = sourceCollection + "/" + CTS::CTSLib.pathForUrn(versionUrn,pubtype)
    
    # check to see if the user is already working on the parent publication
    @publication = nil
    existing_identifiers = CTSIdentifier::find_matching_identifiers(versionIdentifier,@current_user,nil)
        
    if existing_identifiers.length > 0
      conflicting_publication = existing_identifiers.first.publication
      conflicting_publications = existing_identifiers.collect {|ci| ci.publication}.uniq
  
      if conflicting_publications.length > 1
        flash[:error] = 'Error creating publication: multiple conflicting publications'
        flash[:error] += '<ul>'
        conflicting_publications.each do |conf_pub|
          flash[:error] += "<li><a href='#{url_for(conf_pub)}'>#{conf_pub.title}</a></li>"
        end
        flash[:error] += '</ul>'
        redirect_to dashboard_url
        return
      end # end more than one conflicting publication
  
      if (conflicting_publication.status == "committed")
        expire_publication_cache
        conflicting_publication.archive
      else
        @publication = conflicting_publication 
      end
    end # end test of possible conflicts
    
    if @publication.nil?
       # User doesn't have the parent publication yet so create it
       identifiers_hash = Hash.new
       [versionIdentifier,OACIdentifier.make_name(versionIdentifier)].each do |id|
        key = CTS::CTSLib.getIdentifierKey(id)
        identifiers_hash[key] = Array.new()
        identifiers_hash[key] << id
       end
       @publication = Publication.new()
       @publication.owner = @current_user
       @publication.creator = @current_user
      
      if (existing_identifiers.length == 0) 
        # HACK for IDigGreek to enable link in to create annotations on an edition that doesn't
        # exist in the master repo
        temp_id = nil
        identifier_class = nil
        SITE_IDENTIFIERS.split(",").each do |identifier_name|
          ns = identifier_name.constantize::IDENTIFIER_NAMESPACE
          if CTS::CTSLib.getIdentifierKey(versionIdentifier) == ns
          
            identifier_class = Object.const_get(identifier_name)
            temp_id = identifier_class.new(:name => versionIdentifier)
          end
        end
        
        if (@publication.repository.get_file_from_branch(temp_id.to_path, 'master').blank?)
          fullurn = "urn:cts:#{versionUrn}"
          # fetch a title without creating from template
          @publication.title = identifier_class.new(:name => identifier_class.next_temporary_identifier(sourceCollection,fullurn,'edition','ed')).name
          @publication.status = "new"
          @publication.save!
      
          lang = params[:lang] || 'en'
          # branch from master so we aren't just creating an empty branch
          @publication.branch_from_master
          new_cts = identifier_class.new_from_template(@publication,sourceCollection,fullurn, pubtype,lang)
                     
          # create the inventory metadata records
          # we can't do this until the publication has already been branched from the master 
          # because it doesn't exist in the master git repo 
          # and is only carried along with the publication until it is finalized
          begin
            # first the inventory record
            Rails.logger.info("Create inventory file from branch blank")
            CTSInventoryIdentifier.new_from_template(@publication,sourceCollection,versionIdentifier,versionUrn)
          rescue Exception => e
            @publication.destroy
            flash[:notice] = 'Error creating publication (during creation of inventory excerpt):' + e.to_s
            redirect_to dashboard_url
            return
          end
    
        else
          @publication.populate_identifiers_from_identifiers(
              identifiers_hash,CTS::CTSLib.versionTitleForUrn(sourceCollection,"urn:cts:#{versionUrn}"))
                     
          if @publication.save!
            @publication.branch_from_master
          
            # create the temporary CTS citation and inventory metadata records
            # we can't do this until the publication has already been branched from the master 
            # because they don't exist in the master git repo 
            # and are only carried along with the publication until it is finalized
            begin
              # first the inventory record
              Rails.logger.info("Create inventory file from branch")
              CTSInventoryIdentifier.new_from_template(@publication,sourceCollection,versionIdentifier,versionUrn)
            rescue Exception => e
              @publication.destroy
              flash[:notice] = 'Error creating publication (during creation of inventory excerpt):' + e.to_s
              redirect_to dashboard_url
              return
            end # end creating inventory record
  
            # need to remove repeat against publication model
            e = Event.new
            e.category = "started editing"
            e.target = @publication
            e.owner = @current_user
            e.save!
          end # end saving new publication
        end # now we have a publication
      end
    end    
    Rails.logger.info("Publication #{@publication.inspect} Identifiers #{@publication.identifiers.inspect}")
    redirect_to(:controller => 'citation_cts_identifiers', 
                :action => 'confirm_edit_or_annotate', 
                :publication_id => @publication.id,
                :version_id => versionIdentifier,
                :collection => sourceCollection,
                :urn => citationUrn,
                :src => sourceRepo)   
  end
  
  ###
  # Creates a new CTS identifier from the CTS selector element
  ###
  def create_from_selector
    edition = params[:edition_urn]
    if (edition.nil?)
      # if no edition, just use a fake one for use in path processing
      edition = "urn:cts:" + params[:work_urn] + ".tempedition"
    end    
    collection = params[:CTSIdentifierCollectionSelect]
    identifier = collection + "/" + CTS::CTSLib.pathForUrn(edition,'edition')
    identifier_class = Object.const_get(CTS::CTSLib.getIdentifierClassName(identifier))

    if (params[:commit] == "Create Edition")
      lang = params[:lang]
      # TODO figure out language for new editions from inventory
      lang ||= 'en'
      new_publication = Publication.new(:owner => @current_user, :creator => @current_user)
      urn = "urn:cts:#{edition}"
      # fetch a title without creating from template
      new_publication.title = identifier_class.new(:name => identifier_class.next_temporary_identifier(collection,urn,'edition',lang)).name
      Rails.logger.info("Creating new title #{new_publication.title}")
      new_publication.status = "new"
      new_publication.save!
    
      # branch from master so we aren't just creating an empty branch
      new_publication.branch_from_master
    
      # create the new template
      new_cts = identifier_class.new_from_template(new_publication,collection,urn,'edition',lang)
      @publication = new_publication
      
      # create the temporary CTS citation and inventory metadata records
      # we can't do this until the publication has already been branched from the master 
      # because they don't exist in the master git repo 
      # and are only carried along with the publication until it is finalized
      begin
        # first the inventory record
        CTSInventoryIdentifier.new_from_template(@publication,collection,identifier,edition)
        # now the citation identifier 
        if params[:citation_urn]
          # TODO this needs to support direction creation from a translation as well as an edition?
          citation_identifier = CitationCTSIdentifier.new_from_template(@publication,collection,params[:citation_urn].to_s,'edition')
        end
      rescue Exception => e
        @publication.destroy
        flash[:notice] = 'Error creating publication (during creation of inventory excerpt):' + e.to_s
        redirect_to dashboard_url
        return
      end


      flash[:notice] = 'Publication was successfully created.'
      expire_publication_cache
      redirect_to @publication
    
    # proceed to create from existing identifier file -- only if we have an identifier
    elsif (params[:edition_urn])
      conflicting_identifiers = CTSIdentifier::find_matching_identifiers(identifier,@current_user,nil)
      
      if conflicting_identifiers.length > 0
        Rails.logger.info("Conflicting identifiers: #{conflicting_identifiers.inspect}")
        conflicting_publication = conflicting_identifiers.first.publication
        conflicting_publications = conflicting_identifiers.collect {|ci| ci.publication}.uniq
  
        if conflicting_publications.length > 1
          flash[:error] = 'Error creating publication: multiple conflicting publications'
          flash[:error] += '<ul>'
          conflicting_publications.each do |conf_pub|
            flash[:error] += "<li><a href='#{url_for(conf_pub)}'>#{conf_pub.title}</a></li>"
          end
          flash[:error] += '</ul>'
          redirect_to dashboard_url
          return
        end
  
        if (conflicting_publication.status == "committed")
          expire_publication_cache
          conflicting_publication.archive
        else
          flash[:error] = "Error creating publication: publication already exists. Please delete the <a href='#{url_for(conflicting_publication)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
          redirect_to dashboard_url
          return
        end
      end # end if conflicting identifiers
      # else
      identifiers_hash = Hash.new
      
      key = CTS::CTSLib.getIdentifierKey(identifier)
      identifiers_hash[key] = Array.new()
      identifiers_hash[key] << identifier
      
      @publication = Publication.new()
      @publication.owner = @current_user
      @publication.creator = @current_user
      @publication.populate_identifiers_from_identifiers(
            identifiers_hash,CTS::CTSLib.versionTitleForUrn(collection,params[:edition_urn].to_s))
                   
      if @publication.save!
        @publication.branch_from_master
        
        # create the temporary CTS citation and inventory metadata records
        # we can't do this until the publication has already been branched from the master 
        # because they don't exist in the master git repo 
        # and are only carried along with the publication until it is finalized
        begin
          # first the inventory record
          CTSInventoryIdentifier.new_from_template(@publication,collection,identifier,edition)
          # now the citation identifier 
          if params[:citation_urn]
            # TODO this needs to support direction creation from a translation as well as an edition?
            citation_identifier = CitationCTSIdentifier.new_from_template(@publication,collection,params[:citation_urn].to_s,'edition')
          end
        rescue Exception => e
          @publication.destroy
          flash[:notice] = 'Error creating publication (during creation of inventory excerpt):' + e.to_s
          redirect_to dashboard_url
          return
        end


        # need to remove repeat against publication model
        e = Event.new
        e.category = "started editing"
        e.target = @publication
        e.owner = @current_user
        e.save!
  
        flash[:notice] = 'Publication was successfully created.'
        expire_publication_cache
        #redirect_to edit_polymorphic_path([@publication, @publication.entry_identifier])
        redirect_to @publication
      else
        flash[:notice] = 'Error creating publication'
        redirect_to dashboard_url
      end  # end if save
    else
        flash[:notice] = 'You must specify an edition.'
        redirect_to dashboard_url
    end # end if creating from inventory
    
  end # end create_from_selector
  
  def create_from_uri
    # check agent
    agent = AgentHelper::agent_of(params[:uri])
    if (agent.nil?)
      flash[:error] = "Unrecognized Link Agent #{params[:uri]}"
      redirect_to dashboard_url
    end

    collection = agent[:collections][:CTSIdentifier]

    # retrieve URI
    begin
      linked_uri = URI.parse(params[:uri])
      resp = Net::HTTP.start(linked_uri.host, linked_uri.port) do |http|
        http.send_request('GET',linked_uri.request_uri)
      end
      if (resp.code == '200')
        content = resp.body
      else 
        raise "Failed request to #{linked_uri} : #{resp.code} #{resp.msg} #{resp.body}" 
      end
    rescue Exception => e
      flash[:error] = e.get_message
      redirect_to dashboard_url and return
    end
    
    if (agent[:transformations][:CTSIdentifier])
      transform = agent[:transformations][:CTSIdentifier]
    end
    unless (transform.nil?)
      user = ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => @current_user.name, :only_path => false)
      content = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT, transform)),
      'uri' => params[:uri],
      'current_user' => user,
      'emend' => params[:emend],
      'lang' => params[:lang]
      )  
    end

    xml = REXML::Document.new(content).root
    # retrieve urn and pubtype from content 
    create = REXML::XPath.first(xml, "/create[@urn]")
    unless (create.nil?)
      urn = create.attributes['urn']
      pubtype = create.attributes['pubtype']
      if (urn.nil? || pubtype.nil?)
        flash[:error] = "Unable to parse CTS urn or pubtype from retrieved content: #{content}"
        redirect_to dashboard_url and return
      end
    end 
    
    begin
      urnObj = CTS::CTSLib.urnObj(urn)
    rescue
      flash[:error] = "Invalid URN identifier for linked text #{urn}}"
      redirect_to dashboard_url and return
    end
    
    # we must have at least a work
    work = urnObj.getWork(false)
    if (work.nil? || work == '')
      flash[:error] = "Missing work identifier for linked text #{urn}}"
      redirect_to dashboard_url and return
    end
    
    version = urnObj.getVersion(false)
    Rails.logger.info("Checking for version #{version}")
    if (version.nil? || version == '')
      # if no edition, just use a fake one for use in path processing
      version = urn + ".tempedition"    
      identifier = collection + "/" + CTS::CTSLib.pathForUrn(version,pubtype)
      identifier_class = Object.const_get(CTS::CTSLib.getIdentifierClassName(identifier))
      new_publication = Publication.new(:owner => @current_user, :creator => @current_user)
      # fetch a title without creating from template
      new_publication.title = identifier_class.new(:name => identifier_class.next_temporary_identifier(collection,urn,pubtype,'pub')).name
      new_publication.status = "new"
      new_publication.save!
      @publication = new_publication
      # branch from master so we aren't just creating an empty branch
      new_publication.branch_from_master
    
      # create the new templates
      begin     
        identifier_class.parse_docs(content).each{ |doc|
          new_cts = identifier_class.new_from_supplied(new_publication,collection,urn,pubtype,doc[:lang],doc[:contents])
        }
      rescue Exception => e
        @publication.destroy
        flash[:notice] = 'Error initializing content:' + e.to_s
        redirect_to dashboard_url
        return
      end
      
      # create the temporary CTS citation and inventory metadata records
      # we can't do this until the publication has already been branched from the master 
      # because they don't exist in the master git repo 
      # and are only carried along with the publication until it is finalized
      begin
        # first the inventory record
        CTSInventoryIdentifier.new_from_template(@publication,collection,identifier,version)
        # now the citation identifier 
      rescue Exception => e
        @publication.destroy
        flash[:notice] = 'Error creating publication (during creation of inventory excerpt):' + e.to_s
        redirect_to dashboard_url
        return
      end

      flash[:notice] = 'Publication was successfully created.'
      expire_publication_cache
      redirect_to @publication
    # proceed to create from existing identifier file -- only if we have an identifier
    else
      raise "Editing an existing edition from URI is not yet supported"
    end # end if editing existing edition       
  end
  
end
