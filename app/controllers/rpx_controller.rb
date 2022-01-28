require 'rpx'

class RpxController < ApplicationController
  # layout 'site'

  protect_from_forgery except: %i[login_return associate_return]

  def remove_openid
    user_identifier = UserIdentifier.find_by(id: params[:openid].to_s)
    if user_identifier.nil?
      flash[:error] = 'OpenID Disassociation Failed: No such OpenID'
      redirect_to controller: 'user', action: 'account'
      return
    end

    user = user_identifier.user

    if user.id == @current_user.id
      if user.user_identifiers.length > 1
        flash[:notice] = "OpenID #{user_identifier.identifier} removed"
        user_identifier.destroy
      else
        flash[:error] = 'OpenID Disassociation Failed: Your account must have at least one OpenID'
      end
      redirect_to controller: 'user', action: 'account'
    else
      flash[:error] = 'OpenID Disassociation Failed: ID not owned by user'
      redirect_to controller: 'user', action: 'account'
      nil
    end
  end

  def associate_return
    if params[:error]
      flash[:error] = "OpenID Authentication Failed: #{params[:error]}"
      redirect_to controller: 'welcome', action: 'index'
      return
    end

    unless params[:token]
      flash[:notice] = 'OpenID Authentication Cancelled'
      redirect_to controller: 'welcome', action: 'index'
      return
    end

    # FIXME: Glassfish reqeust object seems to ignore context root?
    # data = @rpx.auth_info(params[:token].to_s, request.url)
    data = @rpx.auth_info(params[:token].to_s,
                          url_for(controller: :rpx, action: :associate_return, only_path: false))

    identifier = data['identifier']
    user_identifier = UserIdentifier.find_by(identifier: identifier)

    if user_identifier.nil?
      if @current_user.nil?
        flash[:notice] = 'you are not signed in'
      else
        @current_user.user_identifiers << UserIdentifier.create(identifier: identifier)
        flash[:notice] = "#{identifier} added to your account"
      end
    elsif @current_user.id == user_identifier.user.id
      flash[:notice] = 'That OpenID was already associated with this account'
      redirect_to controller: 'user', action: 'account'
    else
      # The OpenID was already associated with a different user account.
      # @page_title = "Replace OpenID Account"
      # session[:identifier] = identifier
      # @other_user = User.find_by_id primary_key
      flash[:error] = "OpenID #{identifier} is already associated with a different user account."
    end
    redirect_to controller: 'user', action: 'account'
  end

  def associate_really
    # This is from the RPX template code, but we don't use it.
    # identifier = session[:identifier]
    # session[:identifier] = nil
    #
    # if params[:confirm] == "Yes"
    #   @rpx.map identifier, @current_user.id
    #   flash[:notice] = "#{identifier} added to your account"
    # else
    #   flash[:notice] = "No OpenID was added to your account"
    # end
    #
    # redirect_to :controller => "site", :action => "index"
  end

  def login_return
    if params[:error] || !params[:token]
      flash[:notice] = 'Sign-in cancelled'
      redirect_to controller: 'welcome', action: 'index'
      return
    end

    # FIXME: Glassfish reqeust object seems to ignore context root?
    # data = @rpx.auth_info(params[:token].to_s, request.url)
    data = @rpx.auth_info(params[:token].to_s,
                          url_for(controller: :rpx, action: :login_return, only_path: false, protocol: 'https'))

    identifier = data['identifier']

    user_identifier = UserIdentifier.find_by(identifier: identifier)
    unless user_identifier
      begin
        unless guess_email(data) == '' # some providers don't return email addresses
          user = User.find_by(email: guess_email(data))
          if user
            user_identifier = UserIdentifier.create(identifier: identifier)
            user.user_identifiers << user_identifier
            user.save!
          end
        end
      rescue StandardError => e
        user_identifier&.destroy
        Rails.logger.error("identifier association error: #{e.inspect}\n#{e.backtrace}")
      end
    end

    if user_identifier
      # User Identifier exists, login and redirect to index
      user = user_identifier.user
      session[:user_id] = user.id
      # redirect_to :controller => "welcome", :action => "index"
      # redirect to dashboard
      if session[:entry_url].blank?
        redirect_to controller: 'user', action: 'dashboard'
      else
        redirect_to session[:entry_url]
        session[:entry_url] = nil
      end
      nil
    else
      session[:identifier] = identifier
      @name = guess_name(data)
      @email = guess_email(data)
      @full_name = guess_full_name(data)
    end
  end

  def create_submit
    identifier = session[:identifier]
    if params[:new_user]
      @name = params[:new_user][:name]
      @email = params[:new_user][:email]
      @full_name = params[:new_user][:full_name]
    end

    if @name.empty?
      flash.now[:error] = 'Nickname must not be empty'
      render action: 'login_return'
      return
    end

    begin
      user = User.create(name: @name, email: @email, full_name: @full_name)
      # this save to execute validates_uniqueness_of :name so not continue with duplicate
      user.save!
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:error] = 'Nickname not available'
      render action: 'login_return'
      return
    end

    begin
      # If for any reason the RPX association step fails, we want to
      # be sure to recover from it and roll back any changes made up
      # to this point.  Otherwise, the user account will have been
      # created with no identifier associated with it.
      user.user_identifiers << UserIdentifier.create(identifier: identifier)
      user.save!
    rescue StandardError => e
      user.destroy
      flash.now[:error] = "An error occurred when attempting to create your account; try again. #{e.inspect}"
      render action: 'login_return'
      return
    end

    session[:user_id] = user.id
    session[:identifier] = nil

    if session[:entry_url].blank?
      redirect_to controller: 'welcome', action: 'index'
    else
      redirect_to session[:entry_url]
      session[:entry_url] = nil
      nil
    end
  end

  private

  def guess_name(data)
    if data['displayName']
      return data['displayName']
    elsif data['preferredUsername']
      return data['preferredUsername']
    end

    # There wasn't anything, so let the user enter a nickname.
    ''
  end

  def guess_email(data)
    if data['verifiedEmail']
      return data['verifiedEmail']
    elsif data['email']
      return data['email']
    end

    ''
  end

  def guess_full_name(data)
    if data['name']
      if data['name']['formatted']
        return data['name']['formatted']
      elsif data['name']['familyName'] || data['name']['givenName']
        return [data['name']['givenName'], data['name']['familyName']].join(' ')
      end
    end

    ''
  end
end
