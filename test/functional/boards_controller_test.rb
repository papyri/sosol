require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  def setup
    @admin = Factory(:admin)
    @request.session[:user_id] = @admin.id
    @board = Factory(:board)
    @board_two = Factory(:board)
  end
  
  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
    @board.destroy unless !Board.exists? @board.id
    @board_two.destroy unless !Board.exists? @board_two.id
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
      post :create, :board => Factory.build(:board).attributes
    end

    assert_redirected_to edit_board_path(assigns(:board))
    assigns(:board).destroy
  end

  test "should show board" do    
    get :show, :id => @board.id
    assert_response :success
  end

  test "should get edit" do    
    get :edit, :id => @board.id
    assert_response :success
  end

  test "should update board" do    
    put :update, :id => @board.id, :board => { }
    assert_redirected_to board_path(assigns(:board))
  end

  test "should destroy board" do
    assert_difference('Board.count', -1) do
      delete :destroy, :id => @board.id
    end

    assert_redirected_to boards_path
  end
end
