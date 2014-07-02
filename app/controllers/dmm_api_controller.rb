# controller for the Data Management Module API
class DmmApiController < ApplicationController
  
  before_filter :authorize
  before_filter :ownership_guard, :only => [:api_item_patch, :api_item_append]
  
  # minutes for csrf session cookie expiration
  CSRF_COOKIE_EXPIRE = 60

  def api_item_create
    begin
      # Reset the expiration time on the csrf cookie (should really be handled by OAuth)
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :expires => CSRF_COOKIE_EXPIRE.minutes.from_now # TODO configurable
      }
      params[:raw_post] = request.raw_post
      unless (params[:comment]) 
        params[:comment] = "create_from_api"
      end
      identifier_class = identifier_type
      tempid = identifier_class.api_parse_post_for_identifier(params[:raw_post])
      existing_identifiers = identifier_class.find_matching_identifiers(tempid,@current_user,params[:init_value])
      # TODO errors should include links to existing publications
      if existing_identifiers.length > 1
        list = existing_identifiers.collect{ |p|p.name}.join(',')
        render :xml => "<error>Multiple conflicting identifiers( #{list})</error>", :status => 500
        return
      elsif existing_identifiers.length == 1
        conflicting_publication = existing_identifiers.first.publication
        if (conflicting_publication.status == "committed")
          expire_publication_cache
          conflicting_publication.archive
        else
           render :xml => "<error>Conflicting identifier.( #{existing_identifiers.first.name})</error>", :status => 500
           return
        end
      end # end test of possible conflicts
        
      # User doesn't have conflicts so create the publication yet so create if we weren't given one
      if (params[:publication_id])
        find_publication
      else
        @publication = Publication.new()
        @publication.owner = @current_user
        @publication.creator = @current_user
        @publication.title = identifier_class::create_title(tempid)   
        @publication.status = "new"
        @publication.save!
        
        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      end    
      
      agent = agent_of(params[:raw_post])
      new_identifier_uri = identifier_class.api_create(@publication,agent,params[:raw_post],params[:comment])
    rescue Exception => e
      Rails.logger.error(e.backtrace)
      render :xml => "<error>#{e}</error>", :status => 500
      return   
    end
    render :xml => "<item>#{new_identifier_uri.id}</item>"
    return 
  end

  def api_item_append
     # add the raw post to the session
    params[:raw_post] = request.raw_post
    unless (params[:comment]) 
      params[:comment] = "append_from_api"
    end
    find_identifier
    if (@identifier.nil?)
      render :xml => '<error>Unrecognized Identifier Type</error>', :status => 500
    else
      # TODO we need to look at the etags to make sure we're editing the correct version
            
      # Reset the expiration time on the csrf cookie (should really be handled by OAuth)
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :expires => CSRF_COOKIE_EXPIRE.minutes.from_now # TODO configurable
      }
      agent = agent_of(params[:raw_post])

      begin
        response = @identifier.api_append(agent,params[:raw_post],params[:comment]) 
      rescue Exception => e
        Rails.logger.error(e.backtrace)
        render :xml => "<error>#{e}</error>", :status => 500
        return
      end
      render :xml => "<item>#{response}</item>"
    end
  end
  
  # responds to a POST (s/b PATCH) request to update a file (TODO - need to update rails to get PATCH support)
  # @param [String] identifier_type
  # @param [String] id - the unique id of the identifier
  # @param [String] q - an optional query string which may be customized per identifier type
  # TODO the path should be specified in the body of the PATCH e.g. using json-patch or xml-patch
  # TODO the comment should be specified in the body of the PATCH
  def api_item_patch
    identifier_class = nil
    # add the raw post to the session
    params[:raw_post] = request.raw_post
    unless (params[:comment]) 
      params[:comment] = "update_from_api"
    end
    find_identifier
    if (@identifier.nil?)
      render :xml => '<error>Unrecognized Identifier Type</error>', :status => 500
    else
      # TODO we need to look at the etags to make sure we're editing the correct version
      
      # we need to expire the api_get cache for the identifier now that it's been updated
      expire_api_item_cache(params[:identifier_type],params[:id])
      
      # Reset the expiration time on the csrf cookie (should really be handled by OAuth)
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :expires => CSRF_COOKIE_EXPIRE.minutes.from_now # TODO configurable
      }
      agent = agent_of(params[:raw_post])
      begin
        response = @identifier.api_update(agent,params[:q],params[:raw_post],params[:comment]) 
      rescue Exception => e
        Rails.logger.error(e.backtrace)
        render :xml => "<error>#{e}</error>", :status => 500
        return
      end
      render :xml => response
    end
  end
  
  # responds to a GET request to retrieve a file
  # @param [String] identifier_type
  # @param [String] id - the unique id of the identifier
  # @param [String] q - an optional query string which may be customized per identifier type
  # @response atompub? HAL?  
  #           Authentication should be via oauth2 - for now assume session is shared and 
  #           use X-CSRF-Token
  def api_item_get
    find_identifier
    if (@identifier.nil?)
      render :xml => {:error => "Unrecognized Identifier Type"}, :status => 500
    else
      # Set a cookie so that the calling app can access the session
      # TODO this should be protected by OAuth
      # for now limit the lifetime to an hour 
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :expires => CSRF_COOKIE_EXPIRE.minutes.from_now # TODO configurable
      }
      render :xml => @identifier.api_get(params[:q]) 
    end
  end
  
  # responds to a GET request to retrieve information about a file
  # @param [String] identifier_type
  # @param [String] id - the unique id of the identifier
  # @param [String] format - the requested format (optional - if not specified default is xml)
  # @response atompub? HAL?  
  #           Authentication should be via oauth2 - for now assume session is shared and 
  #           use X-CSRF-Token
  def api_item_info
    find_identifier
    
    if (@identifier.nil?)
      if (params[:format] == 'json')
        render :json => {:error => "Unrecognized Identifier Type"}, :status => 500
      else
        render :xml => {:error => "Unrecognized Identifier Type"}, :status => 500
      end
    else
      # build up some urls to send to the model
      urls = {}
      urls['self'] = polymorphic_url([@identifier.publication,@identifier])
      if (@identifier.respond_to? :parentIdentifier)
        urls['parent']  = polymorphic_url([@identifier.publication,@identifier.parentIdentifier]) 
      else
        urls['parent'] = nil
      end
      urls['root'] = "#{root_url}"
      if (params[:format] == 'json')
        render :json => @identifier.api_info(urls)
      else
        render :xml => @identifier.api_info(urls)
      end
    end
  end
  
  # responds to a GET request to return to the application 
  # @param [String] identifier_type
  # @param [String] id - the unique id of the identifier
  # @param [String] item_action the action on the item to return to
  def api_item_return
    identifier_class = nil
    identifier_class_name = "#{params[:identifier_type]}Identifier"
     begin
      identifier_class_name.constantize::IDENTIFIER_NAMESPACE
      identifier_class = Object.const_get(identifier_class_name)
    rescue Exception => e
      Rails.logger.error(e)
    end   
    if (identifier_class.nil?)
      flash[:error] = "Unrecognized Identifier Type"
      redirect_to dashboard_url
    else
      if (params[:id])
        redirect_to :controller => identifier_class_name.underscore.pluralize,
                  :id => params[:id],
                  :action => params[:item_action]
      else  
        redirect_to dashboard_url
      end
    end
  end
  
  def ping
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :expires => CSRF_COOKIE_EXPIRE.minutes.from_now # TODO configurable
      }
      render :xml => 'OK' 
  end

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
    
    def find_identifier
      identifier_class = identifier_type  
      unless (identifier_class.nil?)
        @identifier = identifier_class.find(params[:id])   
      end
    end
    
    def find_publication
      @publication ||= Publication.find(params[:publication_id].to_s)
    end

    def ownership_guard
      find_identifier
      if !@identifier.publication.mutable_by?(@current_user)
        flash[:error] = 'Operation not permitted.'
        redirect_to dashboard_url
      end
    end
    
    def expire_api_item_cache(a_identifier_type,a_id)
      expire_fragment(:controller => 'dmm_api',
                      :action => 'api_item_get', 
                      :id => a_id,
                      :identifier_type => a_identifier_type)
    end
    
    # looks for the software agent in the data
    # TODO we need to decide upon a standardized approach to this
    def agent_of(a_data)
      unless defined? @agents
        @agents = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config agents.yml})).read).result)[:agents]
      end
      agent = nil
      Rails.logger.info("Agents = #{@agents.inspect}")
      @agents.keys.each do | a_agent |
        if (a_data =~ /#{@agents[a_agent][:uri_match]}/sm)
          agent = @agents[a_agent]
          break
        end
      end
      return agent
    end

end
