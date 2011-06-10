require 'test_helper'

class CommunitiesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:communities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create community" do
    assert_difference('Community.count') do
      post :create, :community => { }
    end

    assert_redirected_to community_path(assigns(:community))
  end

  test "should show community" do
    get :show, :id => communities(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => communities(:one).to_param
    assert_response :success
  end

  test "should update community" do
    put :update, :id => communities(:one).to_param, :community => { }
    assert_redirected_to community_path(assigns(:community))
  end

  test "should destroy community" do
    assert_difference('Community.count', -1) do
      delete :destroy, :id => communities(:one).to_param
    end

    assert_redirected_to communities_path
  end
end
