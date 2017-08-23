# encoding: UTF-8

# controller for the Data Management Module API
class DmmApiController < ApplicationController
  rescue_from Exceptions::CommitError, :with => :commit_failed
  
  before_filter :set_cors_headers
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

  # TODO DEPRECATE APPEND --  ITS JUST A SPECIAL CASE OF PATCH
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
        response = @identifier.patch_content(agent,"APPEND",params[:raw_post],params[:comment])
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
        response = @identifier.patch_content(agent,params[:q],params[:raw_post],params[:comment])
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
      if (params[:q] && params[:q] != '')
        render :xml => @identifier.fragment(params[:q]) and return
      else
        render :xml => @identifier.xml_content() and return
      end
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
      # build up some service info to send to the client
      # backwards compatibility -- should eliminate entirely
      tokenizer = {}
      Tools::Manager.tool_config('cts_tokenizer',false).keys.each do |name|
        tokenizer[name] =  Tools::Manager.link_to('cts_tokenizer',name,:tokenize)[:href]
      end
      info =
        { :tokenizer => tokenizer,
          :cts_services => { 'repos' => "#{root_url}cts/getrepos/#{@identifier.publication.id}",
                             'capabilities' => "#{root_url}cts/getcapabilities/",
                             'passage' => "#{root_url}cts/getpassage/"
                           },
          :target_links => {
            :commentary => [
              {:text => 'Create Commentary',
               :href => "#{root_url}commentary_cite_identifiers/create_from_annotation?publication_id=#{@identifier.publication.id}", :target_param => 'init_value[]'
              }
            ],
          }
        }
      if (params[:format] == 'json')
        render :json => info
      else
        render :xml => info
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
    comments = comments.collect{ | c | format_comment(c) }
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
      render :json => format_comment(comment)
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
      @current_user[:communities] = @current_user.community_memberships.collect{ | c| c.id }
      render :json => @current_user
  end

  protected

    def set_cors_headers
      if ENV['RAILS_ENV'] == "development"
        headers['Access-Control-Allow-Origin'] = Sosol::Application.config.dev_url
        headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
        headers['Access-Control-Request-Method'] = '*'
        headers['Access-Control-Allow-Credentials'] = 'true'
        headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-CSRF-Token'
     end
    end

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
        begin
          agent = AgentHelper::agent_of(params[:raw_post])
        rescue Exception => e
          Rails.logger.error(e)
        end
        
        unless (params[:comment])
          params[:comment] = "create_from_api"
        end
        identifier_class = identifier_type
        tempid, content = identifier_class.identifier_from_content(agent,params[:raw_post])

        # require an exact match on identifier name
        # we want to be able to refine this per identifier type and contents but
        # need a performant solution for that first
        match_callback = lambda do |i| return true end
        existing_identifiers = identifier_class.find_like_identifiers(tempid,@current_user,match_callback)
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
     
        #backwards compatibility - we used to wrap api input in Oa wrappers
        case identifier_class.to_s
        when 'AlignmentCiteIdentifier'
          oacxml = REXML::Document.new(params[:raw_post]).root
          alignment = REXML::XPath.first(oacxml,'//align:aligned-text',{"align" => "http://alpheios.net/namespaces/aligned-text"})
          if (alignment)
            formatter = PrettySsime.new
            formatter.compact = true
            formatter.width = 2**32
            content = ''
            formatter.write alignment, content
          end
        when 'TreebankCiteIdentifier'
          parser = XmlHelper::getDomParser(params[:raw_post],'REXML')
          oacxml = parser.parseroot
          treebank = parser.first(oacxml,"//treebank")
          if (treebank)
            content = parser.to_s(treebank)
          end
        end
        if content.nil?
          content = params[:raw_post]
        end
        @identifier = identifier_class.new_from_supplied(@publication,agent,content,params[:comment])
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
      return @identifier, 200
    end

    # format a comment for the API
    def format_comment(c)
      return {
        :comment_id => c.id,
        :user => c.user.human_name,
        :reason => c.reason,
        :created_at => c.created_at,
        :updated_at => c.updated_at,
        :comment => c.comment
      }
    end

end
