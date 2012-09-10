class CtsPublicationsController < PublicationsController
  layout SITE_LAYOUT
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
    
  ## Create/Update a CTS Publication from a linked URN
  def create_from_linked_urn
    if (params[:urn].blank? || params[:collection].blank?)
      flash[:error] = 'You must specify a URN and a Collection.'
      redirect_to dashboard_url
      return
    end
    
    urnObj = CTS::CTSLib.urnObj(params[:urn])
    sourceRepo = params[:src]
    sourceCollection = params[:collection]
   
    # get the Parent version URN and publication type
    versionUrn = urnObj.getUrnWithoutPassage()
    
    # if the version Urn is the same as the supplied urn then we don't have a citation specified
    citationUrn = (versionUrn == params[:urn]) ? nil :  params[:urn]
    
    pubtype = CTS::CTSLib.versionTypeForUrn(sourceCollection,versionUrn)
    if pubtype.nil?
      flash[:error] = "No publication found for #{params[:urn]} in inventory for #{sourceCollection}"
      redirect_to dashboard_url
      return
    end
    
    versionIdentifier = sourceCollection + "/" + CTS::CTSLib.pathForUrn(versionUrn,pubtype)
    
    # check to see if the user is already working on the parent publication
    @publication = nil
    existing_identifiers = []
    possible_conflicts = Identifier.find_all_by_name(versionIdentifier, :include => :publication)
    actual_conflicts = possible_conflicts.select {|pc| ((pc.publication) && (pc.publication.owner == @current_user) && !(%w{archived finalized}.include?(pc.publication.status)))}
    existing_identifiers += actual_conflicts
        
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
       key = CTS::CTSLib.getIdentifierKey(versionIdentifier)
       identifiers_hash[key] = Array.new()
       identifiers_hash[key] << versionIdentifier
       @publication = Publication.new()
       @publication.owner = @current_user
       @publication.creator = @current_user
       @publication.populate_identifiers_from_identifiers(
            identifiers_hash,nil)
                   
        if @publication.save!
          @publication.branch_from_master
        
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

    # Now if we have a citation, check to see if we already are working on it
    # and if not, create it
    @identifier = nil
    if (citationUrn.nil?)
      @identifier = versionIdentifier
    else
      conflicts = []
      matches = []
      for pubid in @publication.identifiers do 
        if (pubid.kind_of?(CitationCTSIdentifier))
          if (pubid.urn_attribute == citationUrn)
            matches << pubid
          elsif ( pubid.urn_attribute =~ /^#{Regexp.quote(citationUrn)}\./ ||
                  citationUrn =~ /^#{Regexp.quote(pubid.urn_attribute)}\./)
            # A conflicting citation is one which 
            # a - is a parent of the required citation, or 
            # b - is a child of the required citation
            conflicts << pubid
          end # end test for conflicting citation
        end # end test on citation
      end # end loop through publications 
      if conflicts.length >0        
        conflicting_passage = Publication.find(conflicts.first.publication)
        flash[:error] = "You are already editing a parent or child of this citation. Please delete the <a href='#{url_for(@publication)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
        redirect_to dashboard_url
        return
      elsif matches.length == 1        
        @identifier = matches[0]
      elsif matches.length == 0
        #  we don't already have the identifier for this citation so create it
        @identifier = CitationCTSIdentifier.new_from_template(@publication,sourceCollection,citationUrn, pubtype)
      else
        flash[:error] = "One or more conflicting matches for this citation exist. Please delete the <a href='#{url_for(@publication)}'>conflicting publication</a> if you have not submitted it and would like to start from scratch."
        redirect_to dashboard_url
        return
      end
    end # end creation of identifier
    flash[:notice] = "File retrieved."
    expire_publication_cache
      redirect_to polymorphic_path([@publication, @identifier],
                                 :action => :editxml) and return          
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
      lang ||= 'ed'
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

      flash[:notice] = 'Publication was successfully created.'
      expire_publication_cache
      redirect_to @publication
    
    # proceed to create from existing identifier file -- only if we have an identifier
    elsif (params[:edition_urn])
      related_identifiers = [identifier]
      conflicting_identifiers = []
  
      # loop through related identifiers looking for conflicts
      related_identifiers.each do |relid|
          possible_conflicts = Identifier.find_all_by_name(relid, :include => :publication)
          actual_conflicts = possible_conflicts.select {|pc| ((pc.publication) && (pc.publication.owner == @current_user) && !(%w{archived finalized}.include?(pc.publication.status)))}
          conflicting_identifiers += actual_conflicts
        end # end loop through related identifiers
  
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
      
      related_identifiers.each do |relid|
        key = CTS::CTSLib.getIdentifierKey(relid)
        identifiers_hash[key] = Array.new() unless identifiers_hash.has_key?(key)
        identifiers_hash[key] << relid
      end
      
      @publication = Publication.new()
      @publication.owner = @current_user
      @publication.creator = @current_user
      @publication.populate_identifiers_from_identifiers(
            identifiers_hash,nil)
                   
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
            citation_identifier = CitationCTSIdentifier.new_from_template(@publication,collection,params[:citation_urn],'edition')
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
  
end
