require 'test_helper'

class DecreesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:decrees)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create decree" do
    assert_difference('Decree.count') do
      post :create, :decree => { }
    end

    assert_redirected_to decree_path(assigns(:decree))
  end

  test "should show decree" do
    get :show, :id => decrees(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => decrees(:one).id
    assert_response :success
  end

  test "should update decree" do
    put :update, :id => decrees(:one).id, :decree => { }
    assert_redirected_to decree_path(assigns(:decree))
  end

  test "should destroy decree" do
    assert_difference('Decree.count', -1) do
      delete :destroy, :id => decrees(:one).id
    end

    assert_redirected_to decrees_path
  end
end
