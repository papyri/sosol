require 'test_helper'

class EmailersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:emailers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create emailer" do
    assert_difference('Emailer.count') do
      post :create, :emailer => { }
    end

    assert_redirected_to emailer_path(assigns(:emailer))
  end

  test "should show emailer" do
    get :show, :id => emailers(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => emailers(:one).id
    assert_response :success
  end

  test "should update emailer" do
    put :update, :id => emailers(:one).id, :emailer => { }
    assert_redirected_to emailer_path(assigns(:emailer))
  end

  test "should destroy emailer" do
    assert_difference('Emailer.count', -1) do
      delete :destroy, :id => emailers(:one).id
    end

    assert_redirected_to emailers_path
  end
end
