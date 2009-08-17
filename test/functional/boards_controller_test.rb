require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  def setup
    @admin = Factory(:admin)
    @request.session[:user_id] = @admin.id
  end
  
  def teardown
    @request.session[:user_id] = nil
  end
  
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

    assert_redirected_to edit_board_path(assigns(:board))
  end

  test "should show board" do
    board = Factory(:board)
    
    get :show, :id => board.id
    assert_response :success
  end

  test "should get edit" do
    board = Factory(:board)
    
    get :edit, :id => board.id
    assert_response :success
  end

  test "should update board" do
    board = Factory(:board)
    
    put :update, :id => board.id, :board => { }
    assert_redirected_to board_path(assigns(:board))
  end

  test "should destroy board" do
    board_one = Factory(:board, :title => 'board_1')
    board_two = Factory(:board, :title => 'board_2')
    
    assert_difference('Board.count', -1) do
      delete :destroy, :id => board_one.id
    end

    assert_redirected_to boards_path
  end
end
