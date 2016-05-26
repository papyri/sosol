require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CommentaryCiteIdentifier')
  class CommentaryCiteIdentifiersControllerTest < ActionController::TestCase
    def setup
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master

    end
    
    def teardown
      unless @publication.nil?
          @publication.destroy
      end
      @request.session[:user_id] = nil
      @user.destroy
    end

    # TODO ALL TESTS

  end
end
