require 'test_helper'

class CitePublicationsControllerTest < ActionController::TestCase
  def setup
    @user = Factory(:user)
    @request.session[:user_id] = @user.id
  end
  
  def teardown
    @request.session[:user_id] = nil
    @user.destroy
  end
  
  def test_should_make_new_object
    get :create_from_linked_urn, :urn => "urn:cite:perseus:testcoll", :init_value => "http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415", :type => 'Commentary' 
    assert_equal 'Publication was successfully created.', flash[:notice]
    assert_equal 1, assigns(:publication).identifiers.size
  end
  
  def test_should_get_editing_object
    get :create_from_linked_urn, :urn => "urn:cite:perseus:testcoll", :init_value => "http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415", :type => 'Commentary' 
    assert_equal 'Publication was successfully created.', flash[:notice]
    get :create_from_linked_urn, :urn => "urn:cite:perseus:testcoll", :init_value => "http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415", :type => 'Commentary'
    assert_equal 'Edit existing publication.', flash[:notice] 
    assert_equal 1, assigns(:publication).identifiers.size 
  end
  
  #TODO 
  # test_should_use_supplied_title
  # test_should_use_temporary_title
  
end
