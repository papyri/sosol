# encoding: UTF-8

# controller for the Data Management Module API
class DmmApiController < ApplicationController
  rescue_from Exceptions::CommitError, :with => :commit_failed
  
  before_filter :authorize, :except => [:api_item_info, :api_item_get, :preflight_check]
  before_filter :ownership_guard, :only => [:api_item_patch, :api_item_append]
  before_filter :update_cookie

  skip_before_filter :accept_terms # don't display accept_terms on api requests
 
  # this is a temporary work around for cors preflight checks -- the way we have
  # been deploying this so far is to let the Apache proxy deal with the cors
  # but something has changed in rails 3 with regard to options requests - they
  # previously weren't coming through or were just being replied to with a 200
  # but not it seems we have to explicitly handle them. I think there isn't 
  # any real harm here because the post is going to fail anyway but it's clearly
  # not the right way to do this
  def preflight_check
        render :json => {:cors => 'ok'}, :status => 200
  end

  def api_item_create
    response,status = _api_item_create
    if (status == 200)
      response = "<item>#{response.id}</item>"
    else
      response = "<error xmlns:xlink=\"http://www.w3.org/1999/xlink\">#{response}</error>"
    end
    render :xml => response, :status => status
  end

  def api_item_append
     # add the raw post to the session
    params[:raw_post] = request.raw_post.force_encoding("UTF-8")
    unless (params[:comment]) 
      params[:comment] = "append_from_api"
    end
    find_identifier
    if (@identifier.nil?)
        return
    else
      # TODO we need to look at the etags to make sure we're editing the correct version
            
      agent = AgentHelper::agent_of(params[:raw_post])

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
    params[:raw_post] = request.raw_post.force_encoding("UTF-8")
    unless (params[:comment]) 
      params[:comment] = "update_from_api"
    end
    find_identifier
    if (@identifier.nil?)
        return render_error("Unable to locate Document")
    else
      # TODO we need to look at the etags to make sure we're editing the correct version
      
      # we need to expire the api_get cache for the identifier now that it's been updated
      expire_api_item_cache(params[:identifier_type],params[:id])
      
      begin
        agent = AgentHelper::agent_of(params[:raw_post])
        response = @identifier.api_update(agent,params[:q],params[:raw_post],params[:comment])
      rescue Exception => e
        Rails.logger.error(e.backtrace)
        return render :xml => "<error>#{e}</error>", :status => 500
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
    unless (@identifier.nil?)
      render :xml => @identifier.api_get(params[:q]) and return
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
      return
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
    if (params[:id])
      find_identifier
      redirect_to polymorphic_url([@identifier.publication, @identifier], :action => params[:item_action])

    else  
      redirect_to dashboard_url
    end
  end

  # responds to a GET request for comments for an item
  # @param [String] identifier_type
  # @param [String] id - the unique id of the identifier
  # @param [String] q - optional query filter for comment type (set to reason)
  # @returns JSON object, array of comment objects
  def api_item_comments_get
    find_identifier
    if (@identifier.nil?)
      return
    end
    # we get comments on the origin only
    comments = Comment.find_all_by_identifier_id(@identifier.origin.id, :order => 'created_at').reverse
    comments = comments.collect{ | c | c.api_get }
    if (params[:q])
        comments = comments.select{ | c | c[:reason] == params[:q] }
    end 
    render :json => comments
  end

  # responds to a POST request to create/edit a comment
  # @param [String] identifier_type
  # @param [String] id - the unique id of the identifier
  # Body of the post is expected to be a JSON object which mirrors the format
  # of the api_item_comments_get response for an individual comment
  # e.g. 
  #   { 'reason':'review','comment':'comment text' }
  #   { 'reason':'review','comment':'updated comment text', 'comment_id':'1' }
  # for a new comment no comment_id is supplied
  def api_item_comments_post
    find_identifier
    if (@identifier.nil?)
      return
    end

    # set review as the the default reason for a comment if the 
    # commenter is not the owne of the publication  - otherwise its general
    default_reason = @identifier.origin.publication.owner_id != @current_user.id ? 'review' : 'general'
    params[:reason] ||= default_reason
    # hack - need better way to control allowed reasons for commit
    if (params[:reason] !~ /^general|review$/)
      return render_error("Invalid comment reason")
    end 
    rc = false
    if (params[:comment_id]) 
      comment = Comment.find_by_id(params[:comment_id])
      # only update comments that belong to this identifier's origin
      if (comment && comment.identifier_id == @identifier.origin.id)
        comment.comment = params[:comment]
      else 
         return render_error("Invalid or Inaccessible Comment")
      end
    else 
      # we set comments on the origin only
      comment = Comment.new(
        {  :identifier_id => @identifier.origin.id,
           :publication_id => @identifier.publication.origin.id,
           :user_id => @current_user.id,
           :reason => params[:reason],
           :comment => params[:comment],
        })
    end
    if (comment.save)
      render :json => comment.api_get()
    else 
      render_error('Unable to save comment')
    end
  end
 
  ##
  # API request to verify a session exists and set the csrf cookie
  # @returns {String} JSON representation of the user info
  #                   or 403 FORBIDDEN if no session can be established
  ##
  def ping
      @current_user[:uri] = "#{Sosol::Application.config.site_user_namespace}#{URI.escape(@current_user.name)}"
      render :json => @current_user
  end

  protected

    def update_cookie
      expires = Sosol::Application.config.site_cookie_expire_minutes || 60
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :domain => Sosol::Application.config.site_cookie_domain,
        :expires => expires.minutes.from_now
      }
    end

    
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
      if (identifier_class.nil?)
       return render_error("Invalid Identifier Type")
      else
        begin 
          @identifier = identifier_class.find(params[:id])   
        rescue 
          render_error("Invalid Identifier")
        end
      end
    end
    
    def find_publication
      @publication ||= Publication.find(params[:publication_id].to_s)
    end

    def authorize
      if @current_user.nil?
        return render_forbidden('Unable to establish session')
      end
    end


    def ownership_guard
      find_identifier
      if @identifier && !@identifier.publication.mutable_by?(@current_user)
        return render_forbidden('Operation not permitted.')
      end
    end

    def expire_api_item_cache(a_identifier_type,a_id)
      expire_fragment(:controller => 'dmm_api',
                      :action => 'api_item_get', 
                      :id => a_id,
                      :identifier_type => a_identifier_type)
    end

    def commit_failed(e)
        return render_error(e.message)
    end

    # renders an error response
    def render_error(a_msg,a_format=:json)
      if (a_format == 'json') 
        render :json => {:error => a_msg}, :status => 500
      else 
        render :xml => "<error>#{a_msg}</error>", :status => 500
      end
    end

    # renders a forbidden error response
    def render_forbidden(a_msg,a_format=:json)
      if (a_format == 'json') 
        render :json => {:error => a_msg}, :status => 403
      else 
        render :xml => "<error>#{a_msg}</error>", :status => 403
      end
    end
    def _api_item_create
      begin
        # Reset the expiration time on the csrf cookie (should really be handled by OAuth)
      
        params[:raw_post] = request.raw_post.force_encoding("UTF-8") unless params[:raw_post]
        unless (params[:comment]) 
          params[:comment] = "create_from_api"
        end
        identifier_class = identifier_type
        tempid = identifier_class.api_parse_post_for_identifier(params[:raw_post])
        if (params[:init_value] && params[:init_value].length > 0)
          check_match = params[:init_value]
        else
          check_match = identifier_class.api_parse_post_for_init(params[:raw_post])
        end
        # NOTE 2014-08-27 BALMAS this works only for cite_identifier classes right
        # now because the syntax for find_matching_identifier is slightly 
        # different for cts_identifier classes (3rd param is a boolean 
        # for fuzzy matching in that case)
        existing_identifiers = identifier_class.find_matching_identifiers(tempid,@current_user,check_match)
        if existing_identifiers.length > 1
          list = existing_identifiers.collect{ |p|p.name}.join(',')
          return "Multiple conflicting identifiers(#{list})", 500
        elsif existing_identifiers.length == 1
          conflicting_publication = existing_identifiers.first.publication
          if (conflicting_publication.status == "committed")
            conflicting_publication.archive
          else
            links = existing_identifiers.collect{|i| "<link xlink:href=\"#{url_for i.publication}\">#{url_for i.publication}</link>"}
           return "You have conflicting document(s) already being edited at #{links.join(" ")}", 500
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
          if @community
            @publication.community = @community
          end 
          if @publication.save!
            # branch from master so we aren't just creating an empty branch
            @publication.branch_from_master
            e = Event.new
            e.category = "started editing"
            e.target = @publication
            e.owner = @current_user
            e.save!
          else
            return "Error creating new publication", 500
          end  
        end    
     
        # separate begin/rescue block here because
        # we only need to destroy the publication in rescue once we've 
        # successfully created it
        begin 
          agent = AgentHelper::agent_of(params[:raw_post])
          new_identifier_uri = identifier_class.api_create(@publication,agent,params[:raw_post],params[:comment])
        rescue Exception => e
          Rails.logger.error(e.backtrace)
          #cleanup if we created a publication
          if (!params[:publication_id] && @publication)
            @publication.destroy
          end
          return e.message, 500
        end
      rescue Exception => e
        Rails.logger.error(e.backtrace)
        #cleanup if we created a publication
        if (!params[:publication_id] && @publication)
          begin
            @publication.destroy
          rescue Exception => e_2
            Rails.logger.error(e_2.backtrace)
          end
        end
        return e.message, 500
      end
      return new_identifier_uri, 200
    end

end
