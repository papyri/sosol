require 'uri'

class CtsPublicationsController < PublicationsController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
  require 'jruby_xml'  
  
  # Create/Update a CTS Publication from a linked URN
  # - *Params*    :
  # - +urn+ -> the CTS URN of the source passage 
  # - +collection+ -> the CTS inventory name
  # - +pubtype+ -> the type of CTS version ('edition' or 'translation') 
  # - +parent_identifier+ -> the identifier of the parent text document
  #                          in sosol to which the new citation data will
  #                          be added (optional - if not supplied we look
  #                          for an appropriate publication or create one)
  def create_from_linked_urn
    if (params[:urn].blank? || params[:collection].blank?)
      flash[:error] = 'You must specify a URN and a Collection.'
      redirect_to dashboard_url
      return
    end
    
    urnObj = CTS::CTSLib.urnObj(params[:urn].to_s)
    sourceCollection = params[:collection]
    parentIdentifier =  params[:parent_identifier]
   
    # get the Parent version URN and publication type
    versionUrn = urnObj.getUrnWithoutPassage()
    
    # if the version Urn is the same as the supplied urn then we don't have a citation specified
    citationUrn = (versionUrn == params[:urn]) ? nil :  params[:urn]
    
    pubtype = params[:pubtype] || CTS::CTSLib.versionTypeForUrn(sourceCollection,versionUrn)
    if pubtype.nil?
      flash[:error] = "No publication found for #{params[:urn]} in #{sourceCollection} inventory."
      return redirect_to dashboard_url
    end
    
    versionIdentifier = sourceCollection + "/" + CTS::CTSLib.pathForUrn(versionUrn,pubtype)
    
    # check to see if the user is already working on the parent publication
    begin
      # if we were passed a cts identifier, the parent publication is
      # its publication
      if parentIdentifier
        @publication = Identifier.find(parentIdentifier).publication
      # otherwise we linked in from the outside and we need to find out
      # if we are already working on a publication for this text
      else
        @publication = _get_existing_publication(versionIdentifier)
        if (@publication)
          parentIdentifier = @publication.identifiers.select{|i| i.name == versionIdentifier}.first.id.to_s
        end
      end
    rescue Exception => e
      # if we have an exception, we couldn't recover from conflicting 
      # publications - error has already been flashed so just redirect
      Rails.logger.error(e)
      Rails.logger.error(e.backtrace)
      return redirect_to dashboard_url
    end
    
    if @publication.nil?
      # User doesn't have the parent publication yet so create it
      identifiers_hash = Hash.new
      key = CTS::CTSLib.getIdentifierKey(versionIdentifier)
      identifiers_hash[key] = Array.new()
      identifiers_hash[key] << versionIdentifier
      @publication = Publication.new()
      @publication.owner = @current_user
      @publication.creator = @current_user
      @publication.populate_identifiers_from_identifiers(
        identifiers_hash,CTS::CTSLib.versionTitleForUrn(sourceCollection,versionUrn))
                   
      if @publication.save!
        @publication.branch_from_master
        parentIdentifier = @publication.identifiers.first.id.to_s
          
        # create the temporary CTS citation and inventory metadata records
        # we can't do this until the publication has already been branched from the master 
        # because they don't exist in the master git repo 
        # and are only carried along with the publication until it is finalized
        begin
          # first the inventory record
          CTSInventoryIdentifier.new_from_template(@publication,sourceCollection,versionIdentifier,versionUrn)
        rescue Exception => e
          @publication.destroy
          flash[:notice] = 'Error creating publication (during creation of inventory excerpt):' + e.to_s
          return redirect_to dashboard_url
        end # end creating inventory record
  
        # need to remove repeat against publication model
        e = Event.new
        e.category = "started editing"
        e.target = @publication
        e.owner = @current_user
        e.save!
      else
        flash[:error] = "Unable to save publication for #{versionUrn}"
        return redirect_to dashboard_url
      end # end saving new publication
    end # now we have a publication
    redirect_to(:controller => 'citation_cts_identifiers', 
                :action => 'confirm_edit_or_annotate', 
                :publication_id => @publication.id.to_s,
                :collection => sourceCollection,
                :target_uri => "#{root_url}cts/getpassage/#{parentIdentifier}/#{params[:urn]}", 
                :urn => citationUrn)
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
      urn = edition
      # fetch a title without creating from template
      new_publication.title = identifier_class.new(:name => identifier_class.next_temporary_identifier(collection,urn,'edition',lang)).name
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
        inventory = CTSInventoryIdentifier.new_from_template(@publication,collection,identifier,new_cts.urn_attribute)
        inventory.add_edition(new_cts)
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
      rescue Exception => e
        # if we have an exception, we couldn't recover from conflicting 
        # publications - error has already been flashed so just redirect
        flash[:error] = e.message
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
      
      # Debugging
      # Rails.logger.info ':start:'
      # Rails.logger.info identifiers_hash
      # Rails.logger.info CTS::CTSLib.versionTitleForUrn(collection,params[:edition_urn].to_s)
      # Rails.logger.info ':end:'
      
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
      return redirect_to dashboard_url
    end

    collection = agent[:collections][:CTSIdentifier]

    # retrieve content from URL
    begin
      client = AgentHelper::get_client(agent)
      content = client.get_content(params[:id])
    rescue Exception => e
      Rails.logger.error(e.backtrace)
      flash[:error] = e.message
      return redirect_to dashboard_url
    end

    # check to see if we need to transform the retried content
    if (agent[:transformations][:CTSIdentifier])
      transform = agent[:transformations][:CTSIdentifier]
    end

    unless (transform.nil?)
      user = "#{Sosol::Application.config.site_user_namespace}#{URI.escape(@current_user.name)}"
      content = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root, transform)),
      'agent' => params[:agent],
      'id' => params[:id],
      'current_user' => user,
      'lang' => params[:lang],
      'filter' => params[:filter]
      )  
    end

    # retrieve identifier type, urn and pubtype from content 
    parsed = XmlHelper::parseattributes(content,{'create' => ['urn','pubtype','type']})
    if (parsed['create'].length > 0)
      urn = parsed['create'][0]['urn']
      pubtype = parsed['create'][0]['pubtype']
      identifier_type = parsed['create'][0]['type']
    end

    # at minimum we need identifier type, pubtype and urn or we can't proceed
    if (identifier_type.nil? || urn.nil? || pubtype.nil?)
      Rails.logger.error("Unable to parse identifier from #{content}")
      flash[:error] = "Publication not created. Unable to parse identifier."
      return redirect_to dashboard_url
    end

    begin
      urnObj = CTS::CTSLib.urnObj(urn)
    rescue
      flash[:error] = "Publication not created. Invalid URN identifier for linked text #{urn}}"
      return redirect_to dashboard_url
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
      added = 0;
      entry_identifier = nil
      identifier_class.parse_docs(content).each{ |doc|
        ok_to_add = true
        @publication.identifiers.each do |i|
          if i.translation_already_in_language?(doc[:lang])
            flash[:warning] = "You already are editing a translation in that language (#{doc[:lang]}) for this publication"
            entry_identifier = i
            ok_to_add = false
          end
        end
        if (ok_to_add)
          new_cts = identifier_class.new_from_supplied(@publication, agent, doc[:contents], 'Created from Supplied content')
          added = added + 1
          # normally on creation of new publication this should be done with publication.populate_identifiers_from_identifers
          # but we're circumventing that method here
          @publication.identifiers << new_cts
          entry_identifier = new_cts
        end
      }
      if (new_publication)
        flash[:notice] = 'Publication was successfully created.'
      elsif (added > 0)
        flash[:notice] = 'Document was added to existing Publication.'
      end
      expire_publication_cache
    rescue Exception => e
      if (new_publication)
        @publication.destroy
      end
      Rails.logger.error(e)
      flash[:notice] = 'Error creating document:' + e.to_s
      return redirect_to dashboard_url
    end
    redirect_to edit_polymorphic_path([@publication, entry_identifier])
  end

  protected

  def _get_existing_publication(a_identifier,a_fuzzy = false)
    if (a_fuzzy)
      # a fuzzy match assumes any found identifier is a match
      match_callback = lambda do |b| return true end
    else
      # a non-fuzzy match requires an exact match on identifier name
      match_callback = lambda do |b| return b.name == a_identifier end
    end
    existing_identifiers = CTSIdentifier::find_like_identifiers(a_identifier,@current_user,match_callback)

    if existing_identifiers.length > 0
      conflicting_publication = existing_identifiers.first.publication
      conflicting_publications = existing_identifiers.collect {|ci| ci.publication}.uniq
  
      if conflicting_publications.length > 1
        error = 'Error creating publication: multiple conflicting publications'
        error += '<ul>'
        conflicting_publications.each do |conf_pub|
          error += "<li><a href='#{url_for(conf_pub)}'>#{conf_pub.title}</a></li>"
        end
        error += '</ul>'
        raise Exception.new(error)
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
