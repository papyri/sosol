require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryGirl.create(:admin)
    @non_admin = FactoryGirl.create(:user)
    @request.session[:user_id] = @admin.id
    @board = FactoryGirl.create(:board)
    @board_two = FactoryGirl.create(:board)
  end
  
  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
    @non_admin.destroy
    @board.destroy unless !Board.exists? @board.id
    @board_two.destroy unless !Board.exists? @board_two.id
  end

  test "should return forbidden for non-admin" do
    @request.session[:user_id] = @non_admin.id
    get :index
    assert_response :forbidden
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
      post :create, :board => FactoryGirl.build(:board).attributes
    end

    assert_redirected_to edit_board_path(assigns(:board))
    assigns(:board).destroy
  end

  test "should have max rank default" do
    post :create, :board => FactoryGirl.build(:board).attributes
    assert assigns(:board).rank == Board.count
    assigns(:board).destroy
  end
    
  test "should have valid rank" do
    post :create, :board => FactoryGirl.build(:board).attributes
    assert assigns(:board).rank > 0 && assigns(:board).rank <= Board.count
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
