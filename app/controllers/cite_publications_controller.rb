class CitePublicationsController < PublicationsController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
  
  
  # list items currently being edited by user,collection and matching identifier
  def user_collection_list
    if (params[:user_name])
      @user = User.find_by_name(params[:user_name])
    else 
      @user = @current_user
    end
    identifier_class = identifier_type
    match_callback = lambda do |i| return i.name == params[:item_match] end
    existing_identifiers = identifier_class.find_like_identifiers(path_for_collection(params[:collection]),@user,match_callback)
    @publications = existing_identifiers.map{ |i| 
      h = Hash.new
      h[:title] = i.title
      h[:url] =  url_for(:controller => i.class.to_s.underscore.pluralize,:id => i, :action => 'preview')
      h
    }
    unless @publications.length > 0
      flash[:notice] = "No matching publications found!"
    end
    render 'show'
  end

  ## Create/Update a CITE Publication from a linked URN
  def create_from_linked_urn
    ## params[:type] - subclass of CiteIdentifier (e.g. Commentary)
    if (params[:type].blank?)
      flash[:error] = 'You must specify an Object Type.'
      redirect_to dashboard_url
      return
    end
    
    identifier_name = "#{params[:type]}CiteIdentifier"
    identifier_name.constantize::IDENTIFIER_NAMESPACE
    identifier_class = Object.const_get(identifier_name)
    
    # other optional inputs
    ## params[:init_value]  - some string value to use to initialize the object
    ## params[:pub] - publication title
    
    ## if urn and key value are supplied we need to check to see if the requested object exists before
    ## creating it
    if params[:urn] && ! Cite::CiteLib.is_collection_urn?(params[:urn])
      flash[:error] = 'Creating a new version of an existing CITE object is no longer supported via this method'
    end

    # this method will now always create a new publication until we are able to
    # implement performant support for collection item matching

    @publication = Publication.new()
    @publication.owner = @current_user
    @publication.creator = @current_user
      
    ## we will always create a new version in the master repo, just a question of
    ## whether we start fresh or from an existing object
    # fetch a title without creating from template

    @publication.title = identifier_class::create_title(params[:urn])
    @publication.status = "new"
    @publication.save!
    
    # branch from master so we aren't just creating an empty branch
    @publication.branch_from_master
      
    begin
      # we are creating a new object
      @identifier = identifier_class.new_from_template(@publication)

      # Eventually it would be nice to deprecate this in favor of the API
      # but the ability to allow links in is a lightweight way to suppport
      # some customized usage without requiring client programming
      if params[:init_value]
        case identifier_name
        when "CommentaryCiteIdentifier"
          @identifier.update_targets(params[:init_value])
        when "OaCiteIdentifier"
          xform_params = {
            :e_annotatorUri => @identifier.make_annotator_uri(),
            :e_annotatorName => @publication.creator.human_name,
            :e_baseAnnotUri => @identifier.next_annotation_uri()
          }
          params[:init_value].each do |a|
            if  a =~ /urn:cts/
              abbr = CTS::CTSLib.urn_abbr(a)
              cts_targets << abbr
            end
          end
          # if we have all cts targets we use them in the title
          if (cts_targets.size == a_init_value.size)
            @identifier.title = "On #{cts_targets.join(',')}"
          end
          agent_content = (AgenttHelper::content_from_agent(params[:init_value],:OaCiteIdentifier,xform_params))
          @identifier.set_xml_content(agent_content,
              :comment => "Initializing Content with #{params[:init_value].join(',')}")
        when "TreebankCiteIdentifier"
          init_value = params[:init_value][0].to_s
          if (init_value =~ /^https?/)
            conn = Faraday.new(init_value) do |c|
              c.use Faraday::Response::Logger, Rails.logger
              c.use FaradayMiddleware::FollowRedirects, limit: 3
              c.use Faraday::Response::RaiseError
              c.use Faraday::Adapter::NetHttp
            end
            response = conn.get
            if (@identifier.is_valid_xml?(response.body))
              @identifier.set_xml_content(response.body,
                :comment => "Initializing Content from #{init_value}")
            else
              raise Exception.new("Failed to retrieve file at #{init_value} #{response.code}")
            end
          else
            raise Exception.new("Unrecognized init value")
          end
        end
      end
      flash[:notice] = 'Publication was successfully created.'
      # we used to support supplying a custom CITE collection in the link, but it wasn't really uesd
      # so we are using default collections per type now.  At some point when we have a full-featured
      # collections API we may re-enable this, but for now we will just issue a warning if the item
      # went into a different collection than requested
      if @identifier.urn_attribute !~ /#{params[:urn]}/
        flash[:warning] = "The requested CITE collection for this Publication is not available. It has been placed in the defaullt collection for it's type"
      end
    rescue Exception => e
      Rails.logger.error(e)
      Rails.logger.error(e.backtrace)
      @publication.destroy
      flash[:notice] = 'Error creating publication (during creation of collection object):' + e.to_s
      redirect_to dashboard_url
      return
    end
    redirect_to polymorphic_path([@publication, @identifier],
                                   :action => :edit,
                                   :publication_id => @publication.id,
                                   :id => @identifier.id,
                                   :urn => @identifier.urn_attribute)
  end
  
  ###
  # Creates a new CITE Publication from a selector element
  ###
  def create_from_selector
        
  end # end create_from_selector
 
  protected 
    def identifier_type 
      identifier_class_name = "#{params[:identifier_type]}Identifier"        
      begin
        identifier_class_name.constantize::IDENTIFIER_NAMESPACE
        identifier_class = Object.const_get(identifier_class_name)
      rescue Exception => e
        Rails.logger.error(e)
      end
      return identifier_class
    end

end
