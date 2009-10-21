require 'rpx'

class RpxController < ApplicationController
  layout 'site'
  
  def remove_openid
    user_identifier = UserIdentifier.find_by_id(params[:openid])
    if user_identifier.nil?
      flash[:error] = "OpenID Disassociation Failed: No such OpenID"
      redirect_to :controller => "user", :action => "account"
      return
    end
    
    user = user_identifier.user
    
    if user.id == @current_user.id
      if user.user_identifiers.length > 1
        flash[:notice] = "OpenID #{user_identifier.identifier} removed"
        user_identifier.destroy
        redirect_to :controller => "user", :action => "account"
      else
        flash[:error] = "OpenID Disassociation Failed: Your account must have at least one OpenID"
        redirect_to :controller => "user", :action => "account"
      end
    else
      flash[:error] = "OpenID Disassociation Failed: ID not owned by user"
      redirect_to :controller => "user", :action => "account"
      return
    end
  end

  def associate_return
    if params[:error]
      flash[:error] = "OpenID Authentication Failed: #{params[:error]}"
      redirect_to :controller => "welcome", :action => "index"
      return
    end

    if !params[:token]
      flash[:notice] = "OpenID Authentication Cancelled"
      redirect_to :controller => "welcome", :action => "index"
      return
    end

    data = @rpx.auth_info(params[:token], request.url)

    identifier = data["identifier"]
    user_identifier = UserIdentifier.find_by_identifier(identifier)

    if user_identifier.nil?
      if @current_user.nil?
        flash[:notice] = "you are not signed in"
      else
        @current_user.user_identifiers << UserIdentifier.create(:identifier => identifier)
        flash[:notice] = "#{identifier} added to your account"
      end
      redirect_to :controller => "user", :action => "account"
    else
      if @current_user.id == user_identifier.user.id
        flash[:notice] = "That OpenID was already associated with this account"
        redirect_to :controller => "user", :action => "account"
      else
        # The OpenID was already associated with a different user account.
        # @page_title = "Replace OpenID Account"
        # session[:identifier] = identifier
        # @other_user = User.find_by_id primary_key
        flash[:error] = "OpenID #{identifier} is already associated with a different user account."
        redirect_to :controller => "user", :action => "account"
      end
    end
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
      flash[:notice] = "Sign-in cancelled"
      redirect_to :controller => "welcome", :action => "index"
      return
    end

    data = @rpx.auth_info(params[:token], request.url)

    identifier = data["identifier"]
    
    user_identifier = UserIdentifier.find_by_identifier(identifier)

    if user_identifier
      # User Identifier exists, login and redirect to index
      user = user_identifier.user
      session[:user_id] = user.id
      #redirect_to :controller => "welcome", :action => "index"
      #redirect to dashboard
      redirect_to :controller => "user", :action => "dashboard"
    else
      session[:identifier] = identifier
      @name = guess_name data
    end
  end

  def create_submit
    identifier = session[:identifier]
    @name = params[:new_user][:name]

    if @name.empty?
      flash[:error] = "Username must not be empty"
      render :action => "login_return"
      return
    end

    begin
      user = User.create(:name => @name)
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "Username not available"
      render :action => "login_return"
      return
    end

    begin
      # If for any reason the RPX association step fails, we want to
      # be sure to recover from it and roll back any changes made up
      # to this point.  Otherwise, the user account will have been
      # created with no identifier associated with it.
      user.user_identifiers << UserIdentifier.create(:identifier => identifier)
      user.save!
    rescue Exception => e
      user.destroy
      flash[:error] = "An error occurred when attempting to create your account; try again. #{e.inspect}"
      render :action => "login_return"
      return
    end

    session[:user_id] = user.id
    session[:identifier] = nil
    redirect_to :controller => "welcome", :action => "index"
  end

  private

  def guess_name(data)
    if data['displayName']
      return data['displayName']
    end

    # There wasn't anything, so let the user enter a nickname.
    return ''
  end

end
