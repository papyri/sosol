class CtsPublicationsController < PublicationsController
  layout SITE_LAYOUT
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
    
  ###
  # Creates a new CTS identifier from the CTS selector element
  ###
  def create_from_selector
    edition = params[:edition_urn]
    # if no edition, just use a fake one for use in path processing
    if (edition.nil?)
      edition = "urn:cts:" + params[:work_urn] + ".tempedition"
    end
    Rails.logger.info("Trying to create edition #{edition}")
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
    
    # proceed to create from existing identifier file -- only if we have an edition
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
