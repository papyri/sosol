require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryGirl.create(:admin)
    @request.session[:user_id] = @admin.id
    @board = FactoryGirl.create(:board)
    @board_two = FactoryGirl.create(:board)
    @community_board = FactoryGirl.create(:community_board)
  end
  
  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
    @board.destroy unless !Board.exists? @board.id
    @board_two.destroy unless !Board.exists? @board_two.id
    @community_board.destroy unless !Board.exists? @community_board.id
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:boards)
    assert_equal [@board, @board_two], assigns(:boards)['No Community']
    assert_equal [@community_board], assigns(:boards)[@community_board.community.friendly_name]
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
    assert assigns(:board).rank == Board.where(:community_id => nil).count, "Expected #{assigns(:board).rank} to equal #{Board.where(:community_id => nil).count}"
    assigns(:board).destroy
  end

  test "community board should have max rank default" do
    post :create, :board => FactoryGirl.build(:community_board).attributes
    assert assigns(:board).rank == assigns(:board).community.boards.count
    assigns(:board).destroy
  end
    
  test "should have valid rank" do
    post :create, :board => FactoryGirl.build(:board).attributes
    assert assigns(:board).rank > 0 && assigns(:board).rank <= Board.count
    assigns(:board).destroy
  end

  test "community board should have valid rank" do
    post :create, :board => FactoryGirl.build(:community_board).attributes
    assert assigns(:board).rank > 0 && assigns(:board).rank <= assigns(:board).community.boards.count
    assigns(:board).destroy
  end

  test "should show non community boards by rank" do
    get :rank 
    assert assigns(:boards)
    assert_equal [ @board, @board_two ], assigns(:boards)
    assert_equal "", assigns(:community_id)
  end

  test "should show community boards by rank" do
    get :rank, :community_id => @community_board.community.id
    assert assigns(:boards)
    assert_equal [ @community_board ], assigns(:boards)
    assert_equal @community_board.community.id.to_s, assigns(:community_id)
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
