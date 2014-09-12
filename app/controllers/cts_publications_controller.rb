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
    begin
      @publication = _get_existing_publication(versionIdentifier)
    rescue
      # if we have an exception, we couldn't recover from conflicting 
      # publications - error has already been flashed so just redirect
      return redirect_to dashboard_url
    end
    
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
      begin
        existing =  _get_existing_publication(identifier)
      rescue
        # if we have an exception, we couldn't recover from conflicting 
        # publications - error has already been flashed so just redirect
        return redirect_to dashboard_url
      end
      unless (existing.nil?)
        flash[:error] = "Error creating publication: publication already exists. Please delete the <a href='#{url_for(existing)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
        redirect_to dashboard_url
        return
      end
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
  
  def create_from_agent
    # check agent - only registered agents allowed
    agent = AgentHelper::agent_of(params[:agent])
    if (agent.nil? || agent[:api_info].nil?)
      flash[:error] = "Publication not created. Unrecognized API Agent #{params[:agent]}"
      return
    end

    collection = agent[:collections][:CTSIdentifier]

    # retrieve content from URL
    begin
      client = AgentHelper::get_client(agent)
      content = client.get_content(params[:id])
    rescue Exception => e
      Rails.logger.error(e.backtrace)
      flash[:error] = e.message
      return
    end

    # check to see if we need to transform the retried content
    if (agent[:transformations][:CTSIdentifier])
      transform = agent[:transformations][:CTSIdentifier]
    end

    unless (transform.nil?)
      user = ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => @current_user.name, :only_path => false)
      content = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT, transform)),
      'agent' => params[:agent],
      'id' => params[:id],
      'current_user' => user,
      'lang' => params[:lang],
      'filter' => params[:filter]
      )  
    end

    # retrieve identifier type, urn and pubtype from content 
    parsed = XmlHelper::parseattributes(content,{'create',['urn','pubtype','type']})
    if (parsed['create'].length > 0)
      urn = parsed['create'][0]['urn']
      pubtype = parsed['create'][0]['pubtype']
      identifier_type = parsed['create'][0]['type']
    end

    # at minimum we need identifier type, pubtype and urn or we can't proceed
    if (identifier_type.nil? || urn.nil? || pubtype.nil?)
      Rails.logger.error("Unable to parse identifier from #{content}")
      flash[:error] = "Publication not created. Unable to parse collection, CTS urn or pubtype from retrieved content."
      return
    end

    begin
      urnObj = CTS::CTSLib.urnObj(urn)
    rescue
      flash[:error] = "Publication not created. Invalid URN identifier for linked text #{urn}}"
      return
    end
    
    # we must have at least a work
    work = urnObj.getWork(false)
    if (work.nil? || work == '')
      flash[:error] = "Publication not created. Missing work identifier for linked text #{urn}}"
      return redirect_to dashboard_url
    end
    
    version = urnObj.getVersion(false)
    if (version)
      flash[:error] = "Editing an existing edition from URI is not yet supported"
      return redirect_to dashboard_url
    end # end if editing existing edition       

    # if no edition, just use a fake one for use in path processing
    identifier_class = Object.const_get(identifier_type)
    version = urn + "." + identifier_class::TEMPORARY_COLLECTION
    identifier = collection + "/" + CTS::CTSLib.pathForUrn(version,pubtype)

    begin
      @publication = _get_existing_publication(identifier,true)
    rescue Exception => e
      # if we have an exception, we couldn't recover from conflicting 
      # publications - error has already been flashed so just redirect
      Rails.logger.error(e.backtrace)
      return redirect_to dashboard_url
    end

    if (@publication.nil?)
      new_publication = Publication.new(:owner => @current_user, :creator => @current_user)
      # fetch a title without creating from template
      new_publication.title = identifier_class.new(:name => identifier_class.next_temporary_identifier(collection,urn,pubtype,'pub')).name
      new_publication.status = "new"
      Rails.logger.info("Saving #{new_publication.inspect}")
      new_publication.save!
      @publication = new_publication
      # branch from master so we aren't just creating an empty branch
      new_publication.branch_from_master
    end
  
    # create the new templates
    begin     
      identifier_class.parse_docs(content).each{ |doc|
        new_cts = identifier_class.new_from_supplied(@publication,collection,urn,pubtype,doc[:lang],doc[:contents])
      }
      if (new_publication)
        flash[:notice] = 'Publication was successfully created.'
      else 
        flash[:notice] = 'Document was added to existing Publication.'
      end
      expire_publication_cache
    rescue Exception => e
      if (new_publication)
        @publication.destroy
      end
      flash[:notice] = 'Error creating document:' + e.to_s
      return redirect_to dashboard_url
    end
    redirect_to @publication
  end

  protected

  def _get_existing_publication(a_identifier,a_fuzzy = false)
    existing_identifiers = CTSIdentifier::find_matching_identifiers(a_identifier,@current_user,a_fuzzy)

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
        raise "Conflicts"
      end # end more than one conflicting publication
  
      if (conflicting_publication.status == "committed")
        expire_publication_cache
        conflicting_publication.archive
        nil
      else
       conflicting_publication 
      end
    end 
  end
end
