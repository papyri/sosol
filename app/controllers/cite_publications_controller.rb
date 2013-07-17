class CitePublicationsController < PublicationsController
  layout SITE_LAYOUT
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
  
  
  ## Create/Update a CITE Publication from a linked URN
  def create_from_linked_urn
    # required inputs:
    ## params[:urn] = CITE_URN (Collection or Object or Version)
    if (params[:urn].blank?)
      flash[:error] = 'You must specify an Object URN.'
      redirect_to dashboard_url
      return
    end
    
    ## params[:type] - subclass of CiteIdentifier (e.g. Commentary)
    if (params[:type].blank?)
      flash[:error] = 'You must specify an Object Type.'
      redirect_to dashboard_url
      return
    end
    identifier_name = "#{params[:type]}CiteIdentifier"
    identifier_class = Object.const_get(identifier_name)
    
    # other optional inputs
    ## params[:init_value]  - some string value to use to initialize the object
    
    @publication = nil
    ## if urn and key value are supplied we need to check to see if the requested object exists before
    ## creating it
    is_collection_urn = Cite::CiteLib.is_collection_urn?(params[:urn]) 
    if ( is_collection_urn )
      if (params[:init_value])
        lookup_id = CiteIdentifier::path_for_collection(params[:urn])
        existing_identifiers = []
        possible_conflicts = identifier_class.find(:all,
                       :conditions => ["name like ?", "#{lookup_id}%"],
                       :order => "name DESC")
        Rails.logger.info("found possible conflicts #{possible_conflicts.inspect}")
        actual_conflicts = possible_conflicts.select {|pc| 
          ((pc.publication) && 
           (pc.publication.owner == @current_user) && 
           !(%w{archived finalized}.include?(pc.publication.status)) &&
           pc.is_match?(params[:init_value])
          )
        }
        existing_identifiers += actual_conflicts
      end
      # all we have is a collection urn so we must want to create a new object
    elsif (is_object_urn?(params[:urn]))
      ### if publication exists for a version of this object, bring them to it, otherwise create a new version
    elsif (is_version_urn?(params[:urn]))
      ### if publication exists for this version of this object, bring them to it, otherwise raise ERROR
    end # end test on urn type
    
    if existing_identifiers.length > 1
        flash[:error] = 'Error creating publication: multiple conflicting identifiers'
        flash[:error] += '<ul>'
        existing_identifiers.each do |conf_id|
          flash[:error] += "<li><a href='#{url_for(conf_id)}'>#{conf_pub.name}</a></li>"
        end
        flash[:error] += '</ul>'
        redirect_to dashboard_url
        return
    elsif existing_identifiers.length == 1
      conflicting_publication = existing_identifiers.first.publication
      if (conflicting_publication.status == "committed")
        expire_publication_cache
        conflicting_publication.archive
      else
        @publication = conflicting_publication 
      end
    end # end test of possible conflicts
      
    if @publication.nil?
      # User doesn't have the  publication yet so create it
     
      @publication = Publication.new()
      @publication.owner = @current_user
      @publication.creator = @current_user
      
      ## we will always create a new version in the master repo, just a question of 
      ## whether we start fresh or from an existing object
      # fetch a title without creating from template
      @publication.title = identifier_class.new(:name => identifier_class.next_object_identifier(params[:urn])).name
      @publication.status = "new"
      @publication.save!
    
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      
      
      if is_collection_urn
        # we are creating a new object
        new_cite = identifier_class.new_from_template(@publication,params[:urn],params[:init_value])
      else
        # we are creating a new version of an existing object
        new_cite = identifier_class.new_from_inventory(@publication,params[:urn])
      end
      flash[:notice] = 'Publication was successfully created.'      
    else
      new_cite = existing_identifiers.first
      flash[:notice] = 'Edit existing publication.'   
    end
    redirect_to polymorphic_path([@publication, @identifier],
                                   :action => :edit,
                                   :publication_id => @publication.id,
                                   :id => new_cite.id,
                                   :urn => new_cite.urn_attribute)
  end
  
  ###
  # Creates a new CITE Publication from a selector element
  ###
  def create_from_selector
        
  end # end create_from_selector
  
end
