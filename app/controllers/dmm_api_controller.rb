# controller for the Data Management Module API
class DmmApiController < ApplicationController
  
  protect_from_forgery :except => [:api_item_get, :api_item_info]
  #before_filter :authorize
  before_filter :ownership_guard, :only => [:api_item_patch, :api_item_get]
  
  # minutes for csrf session cookie expiration
  CSRF_COOKIE_EXPIRE = 60

  
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
      render :xml => {:error => "Unrecognized Identifier Type"}, :status => 500
    else
      # TODO we need to look at the etags to make sure we're editing the correct version
      
      # we need to expire the api_get cache for the identifier now that it's been updated
      expire_api_item_cache(params[:identifier_type],params[:id])
      
      # Reset the expiration time on the csrf cookie (should really be handled by OAuth)
      cookies[:csrftoken] = {
        :value => form_authenticity_token,
        :expires => CSRF_COOKIE_EXPIRE.minutes.from_now # TODO configurable
      }
      
      render :xml => @identifier.api_update(params[:q],params[:raw_post],params[:comment])
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
  # @response atompub? HAL?  
  #           Authentication should be via oauth2 - for now assume session is shared and 
  #           use X-CSRF-Token
  def api_item_info
    find_identifier
    if (@identifier.nil?)
      render :xml => {:error => "Unrecognized Identifier Type"}, :status => 500
    else
      render :xml => @identifier.api_info 
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
  

  protected
    
    def find_identifier
      identifier_class_name = "#{params[:identifier_type]}Identifier"
     begin
      identifier_class_name.constantize::IDENTIFIER_NAMESPACE
      identifier_class = Object.const_get(identifier_class_name)
    rescue Exception => e
      Rails.logger.error(e)
    end
      unless (identifier_class.nil?)
        @identifier = identifier_class.find(params[:id])   
      end
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

end