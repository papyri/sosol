class CollectionIdentifiersController < ApplicationController
  before_filter :authorize
  before_filter :check_ddb

  # Ensures user has DDB rights to view page. Otherwise returns 403 error.
  def check_ddb
    if @current_user.nil? || !(@current_user.boards.select{|b| b.identifier_classes.include?("DDBIdentifier")}.length > 0)
      render :file => 'public/403.html', :status => '403'
    end
  end

  def update
    @short_name = params[:short_name]
    @long_name = params[:long_name]
    @entry_identifier_id = params[:entry_identifier_id]
    @identifier = DDBIdentifier.find(@entry_identifier_id)

    if(@short_name.blank? || @long_name.blank?)
      flash[:error] = "Required attribute missing. Enter both a short and long name."
      redirect_to :action => 'update_review', :short_name => params[:short_name],
        :long_name => params[:long_name], :entry_identifier_id => params[:entry_identifier_id]
      return
    elsif(CollectionIdentifier.new.has_collection?(@short_name))
      flash[:error] = "Collection short name already exists."
      redirect_to :action => 'update_review', :short_name => params[:short_name],
        :long_name => params[:long_name], :entry_identifier_id => params[:entry_identifier_id]
      return
    else
      CollectionIdentifier.new.add_collection(@short_name, @long_name, @current_user)
    end

    flash[:notice] = "Added collection #{@short_name} = #{@long_name}."

    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :rename_review) and return

  end

  def update_review
    @short_name = params[:short_name]
    @entry_identifier_id = params[:entry_identifier_id]
  end
end
