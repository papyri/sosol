class CitePublicationsController < PublicationsController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:confirm_archive, :archive, :confirm_withdraw, :withdraw, :confirm_delete, :destroy, :submit]
  
  
  # list items currently being edited by user,collection and matching identifier
  # - *Params* :
  #   - +user_name+ -> the name of a User (optional - defaults to current user)
  #   - +item_match+ -> an IdentifierType specific match string for comparison
  #   - +collection+ -> the collection to query
  #   - +identifier_type+ -> String containing the subtype of CiteIdentifier to create in the new publication
  def user_collection_list
    if (params[:user_name])
      @user = User.find_by_name(params[:user_name])
    else 
      @user = @current_user
    end
    identifier_class = identifier_type
    #
    match_callback = lambda do |i| return i.respond_to?(:is_match?) ? i.is_match?([params[:item_match]]) : true end
    existing_identifiers = identifier_class.find_like_identifiers(identifier_class.path_for_collection(params[:collection]),@user,match_callback)
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

  # Create/Update a CITE Publication from a linked URN
  # This is an api-ish alternative which enables creation of links into SoSOL from
  # external applications and sites without requiring client side programming of a
  # an api client.
  # - *Params* :
  #   - +identifier_type+ -> String containing the subtype of CiteIdentifier to create in the new publication
  #   - +init_value+ -> Array of String initialization values, which are type-specific
  #   - +
  def create_from_linked_urn
    if (params[:identifier_type].blank?)
      flash[:error] = 'You must specify an Object Type.'
      redirect_to dashboard_url and return
      return
    end
    
    identifier_class = identifier_type

    if params[:urn] && ! Cite::CiteLib.is_collection_urn?(params[:urn])
      flash[:error] = 'Creating a new version of an existing CITE object is no longer supported via this method'
      redirect_to dashboard_url and return
    end

    # this method will now always create a new publication until we are able to
    # implement performant support for collection item matching to find if the user
    # already has followed an identical link

    @publication = Publication.new()
    @publication.owner = @current_user
    @publication.creator = @current_user
      

    @publication.title = identifier_class::create_title(params[:urn])
    @publication.status = "new"
    @publication.save!
    
    # branch from master so we aren't just creating an empty branch
    @publication.branch_from_master
      
    begin
      # Eventually it would be nice to deprecate this in favor of the API
      # but the ability to allow links in is a lightweight way to suppport
      # some customized usage without requiring client programming
      if params[:init_value]
        case identifier_class.to_s
        when "CommentaryCiteIdentifier"
          @identifier = identifier_class.new_from_template(@publication)
          @identifier.update_targets(params[:init_value],"Setting targets from init.")
        when "OaCiteIdentifier"
          @identifier = identifier_class.new_from_template(@publication)
          xform_params = {
            :e_annotatorUri => @identifier.make_annotator_uri(),
            :e_annotatorName => @publication.creator.human_name,
            :e_baseAnnotUri => @identifier.next_annotation_uri()
          }
          cts_targets = []
          params[:init_value].each do |a|
            if  a =~ /urn:cts/
              abbr = CTS::CTSLib.urn_abbr(a)
              cts_targets << abbr
            end
          end
          # if we have all cts targets we use them in the title
          if (cts_targets.size == params[:init_value].size)
            @identifier.title = "On #{cts_targets.join(',')}"
          end
          agent_content = (AgentHelper::content_from_agent(params[:init_value],:OaCiteIdentifier,xform_params))
          @identifier.set_xml_content(agent_content,
              :comment => "Initializing Content with #{params[:init_value].join(',')}")
        when "TreebankCiteIdentifier"
          # backwards compatibility which allows creation of a treebank file from
          # a uri which resolves to a treebank template
          init_value = params[:init_value][0].to_s
          if (init_value =~ /^https?/)
            content = AgentHelper::get_client({:type => 'url'}).get_content(init_value)
            @identifier = identifier_class.new_from_supplied(@publication,init_value,content,"Initializing Content from #{init_value}")
          else
            raise Exception.new("Unrecognized init value")
          end
        end
      else
        @identifier = identifier_class.new_from_template(@publication)
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
      flash[:error] = 'Error creating publication (during creation of collection object):' + e.to_s
      redirect_to dashboard_url
      return
    end
    redirect_to polymorphic_path([@publication, @identifier],
                                   :action => :edit,
                                   :publication_id => @publication.id,
                                   :id => @identifier.id)
  end
  
  protected
    def identifier_type
      identifier_class_name = "#{params[:identifier_type]}CiteIdentifier"
      begin
        identifier_class_name.constantize::IDENTIFIER_NAMESPACE
        identifier_class = Object.const_get(identifier_class_name)
      rescue Exception => e
        Rails.logger.error(e)
      end
      return identifier_class
    end

end
