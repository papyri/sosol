require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class CitePublicationsControllerTest < ActionController::TestCase
    def setup
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
    end
    
    def teardown
      @request.session[:user_id] = nil
      @user.destroy
    end
    
    def test_should_make_new_object
      get :create_from_linked_urn, :urn => "urn:cite:perseus:pdlcomm", :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :type => 'Commentary' 
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_equal 1, assigns(:publication).identifiers.size
    end
    
    def test_should_get_editing_object
      get :create_from_linked_urn, :urn => "urn:cite:perseus:pdlcomm", :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :type => 'Commentary' 
      assert_equal 'Publication was successfully created.', flash[:notice]
      get :create_from_linked_urn, :urn => "urn:cite:perseus:pdlcomm", :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :type => 'Commentary'
      assert_equal 'Edit existing publication.', flash[:notice] 
      assert_equal 1, assigns(:publication).identifiers.size 
    end
    
    def test_should_make_new_object_version
      get :create_from_linked_urn, :urn => "urn:cite:perseus:lattb.1.1", :type => 'Treebank' 
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_equal 1, assigns(:publication).identifiers.size
      assert_equal 'urn:cite:perseus:lattb.1.2', assigns(:publication).identifiers[0].urn_attribute
      assert_not_nil assigns(:publication).identifiers[0].content
    end
    
    def test_should_edit_existing_object_version
      get :create_from_linked_urn, :urn => "urn:cite:perseus:lattb.1.1", :type => 'Treebank' 
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_equal 1, assigns(:publication).identifiers.size
      assert_equal 'urn:cite:perseus:lattb.1.2', assigns(:publication).identifiers[0].urn_attribute
      get :create_from_linked_urn, :urn => "urn:cite:perseus:lattb.1.2", :type => 'Treebank' 
      assert_equal 'Edit existing publication.', flash[:notice] 
      assert_equal 1, assigns(:publication).identifiers.size
    end
    
    
    #TODO 
    # test_should_use_supplied_title
    # test_should_use_temporary_title
    
  end
end
