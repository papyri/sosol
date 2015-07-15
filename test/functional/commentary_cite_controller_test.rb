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
    
    def test_should_fail_invalid_collection
      post :create, :publication_id => @publication.id, :urn => "urn:cite:perseus:junkcoll", :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"] 
      assert_equal 'Unable to create commentary item. Unknown collection.', flash[:error]
    end

    def test_should_fail_duplicate_target
      get :create, :publication_id => @publication.id, :urn => "urn:cite:perseus:pdlcomm", :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"]
      assert_equal 1, @publication.identifiers.size
      get :create, :publication_id => @publication.id, :urn => "urn:cite:perseus:pdlcomm", :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"]
      assert_equal 'You already are editing a commentary for this target.', flash[:notice]
      assert_equal 1, @publication.identifiers.size
    end
    
      
  end
end
