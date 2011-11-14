class CollectionIdentifiersController < ApplicationController
  before_filter :authorize
  before_filter :check_admin

  #Ensures user has admin rights to view page. Otherwise returns 403 error.
  def check_admin
    if @current_user.nil? || !@current_user.admin
      render :file => 'public/403.html', :status => '403'
    end
  end

  def update
    @short_name = params[:short_name]
    @long_name = params[:long_name]
    @entry_identifier_id = params[:entry_identifier_id]
    @identifier = DDBIdentifier.find(@entry_identifier_id)
    flash[:notice] = "Would have added collection #{@short_name} = #{@long_name}."

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :rename_review) and return

  end

  def update_review
    @short_name = params[:collection_name]
    @entry_identifier_id = params[:entry_identifier_id]
  end
end
