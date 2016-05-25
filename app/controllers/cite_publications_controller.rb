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
    identifier_name.constantize::IDENTIFIER_NAMESPACE
    identifier_class = Object.const_get(identifier_name)
    
    # other optional inputs
    ## params[:init_value]  - some string value to use to initialize the object
    ## params[:pub] - publication title
    
    @publication = nil
    ## if urn and key value are supplied we need to check to see if the requested object exists before
    ## creating it
    is_collection_urn = Cite::CiteLib.is_collection_urn?(params[:urn])
    # for now match only only exact match on identifier name
    # we want to be able to match on contents too but requires a more peformant solution
    match_callback = lambda do |i| return true end
    existing_identifiers = identifier_class.find_like_identifiers(path_for_collection(params[:urn]),@current_user,match_callback)

    if existing_identifiers.length > 1
        flash[:error] = 'Error creating publication: multiple conflicting identifiers'
        flash[:error] += '<ul>'
        existing_identifiers.each do |conf_id|
          begin
            flash[:error] += "<li><a href='" + url_for(conf_id) + "'>" + conf_id.name.to_s + "</a></li>"
          rescue
            flash[:error] += "<li>" + conf_id.name.to_s + ":" + conf_id.publication.status + "</li>"
          end
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
      
     
      @publication.title = identifier_class::create_title(params[:urn])
      @publication.status = "new"
      @publication.save!
    
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      
      begin
        if is_collection_urn
          # we are creating a new object
          new_cite = identifier_class.new_from_template(@publication,params[:urn])
          if params[:init_value]
            case identifier_name
            when "CommentaryCiteIdentifier"
              new_cite.update_targets(params[:init_value])
            when "OaCiteIdentifier"
              params = {
                :e_annotatorUri => new_cite.make_annotator_uri(),
                :e_annotatorName => @publication.creator.human_name,
                :e_baseAnnotUri => new_cite.next_annotation_uri()
              }
              params[:init_value].each do |a|
                if  a =~ /urn:cts/
                  abbr = CTS::CTSLib.urn_abbr(a)
                  cts_targets << abbr
                end
              end
              # if we have all cts targets we use them in the title
              if (cts_targets.size == a_init_value.size)
                new_cite.title = "On #{cts_targets.join(',')}"
              end
              agent_content = (AgenttHelper::content_from_agent(params[:init_value],:OaCiteIdentifier,params))
              new_cite.set_xml_content(agent_content,
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
                if (new_cite.is_valid_xml?(response.body))
                  new_cite.set_xml_content(response.body,
                    :comment => "Initializing Content from #{init_value}"
                else
                  Rails.logger.error("Failed to retrieve file at #{init_value} #{response.code}")
                  raise "Supplied URI does not return a valid treebank file"
                end
              else
                Rails.logger.error("Unrecognized init value")
              end
            else
            end
          end
        else
          flash[:error] = 'Cite Versions not supported.'
        end
        flash[:notice] = 'Publication was successfully created.'      
      rescue Exception => e
        Rails.logger.error(e)
        Rails.logger.info(e.backtrace)
        @publication.destroy
        flash[:notice] = 'Error creating publication (during creation of collection object):' + e.to_s
        redirect_to dashboard_url
        return
      end
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
