require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:boards)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create board" do
    assert_difference('Board.count') do
      post :create, :board => { }
    end

    assert_redirected_to board_path(assigns(:board))
  end

  test "should show board" do
    get :show, :id => boards(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => boards(:one).id
    assert_response :success
  end

  test "should update board" do
    put :update, :id => boards(:one).id, :board => { }
    assert_redirected_to board_path(assigns(:board))
  end

  test "should destroy board" do
    assert_difference('Board.count', -1) do
      delete :destroy, :id => boards(:one).id
    end

    assert_redirected_to boards_path
  end
end
