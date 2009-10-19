require 'rpx'

class RpxController < ApplicationController
  layout 'site'
  
  def remove_openid
    identifier = params[:openid]

    @rpx.unmap identifier, @current_user.id
    flash[:notice] = "OpenID #{identifier} removed"

    redirect_to :controller => :welcome, :action => "index"
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
    primary_key = data["primaryKey"]

    if primary_key.nil?
      if @current_user.nil?
        flash[:notice] = "you are not signed in"
      else
        @rpx.map identifier, @current_user.id
        flash[:notice] = "#{identifier} added to your account"
      end
      redirect_to :controller => "welcome", :action => "index"
    else
      if @current_user.id == primary_key.to_i
        flash[:notice] = "That OpenID was already associated with this account"
        redirect_to :controller => "welcome", :action => "index"
      else
        # The OpenID was already associated with a different user account.
        @page_title = "Replace OpenID Account"
        session[:identifier] = identifier
        @other_user = User.find_by_id primary_key
      end
    end
  end

  def associate_really
    identifier = session[:identifier]
    session[:identifier] = nil

    if params[:confirm] == "Yes"
      @rpx.map identifier, @current_user.id
      flash[:notice] = "#{identifier} added to your account"
    else
      flash[:notice] = "No OpenID was added to your account"
    end

    redirect_to :controller => "site", :action => "index"
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
      user.user_identifiers.push(UserIdentifier.create(:identifier => identifier))
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
