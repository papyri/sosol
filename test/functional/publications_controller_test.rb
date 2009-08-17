require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  def setup
    @user = Factory(:user)
    @request.session[:user_id] = @user.id
  end
  
  def teardown
    @request.session[:user_id] = nil
    @user.destroy
  end
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end
end