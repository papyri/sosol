require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryBot.create(:admin)
    @non_admin = FactoryBot.create(:user)
    @request.session[:user_id] = @admin.id
    @board = FactoryBot.create(:board)
    @board_two = FactoryBot.create(:board)
  end

  def teardown
    @request.session[:user_id] = nil
    @admin.destroy
    @non_admin.destroy
    @board.destroy if Board.exists? @board.id
    @board_two.destroy if Board.exists? @board_two.id
  end

  test 'should return forbidden for non-admin' do
    @request.session[:user_id] = @non_admin.id
    get :index, params: {}
    assert_response :forbidden
  end

  test 'should get index' do
    get :index, params: {}
    assert_response :success
    assert_not_nil assigns(:boards)
  end

  test 'should get new' do
    get :new, params: {}
    assert_response :success
  end

  test 'should create board' do
    assert_difference('Board.count') do
      post :create, params: { board: FactoryBot.build(:board).attributes }
    end

    assert_redirected_to edit_board_path(assigns(:board))
    assigns(:board).destroy
  end

  test 'should have max rank default' do
    post :create, params: { board: FactoryBot.build(:board).attributes }
    assert assigns(:board).rank == Board.count
    assigns(:board).destroy
  end

  test 'should have valid rank' do
    post :create, params: { board: FactoryBot.build(:board).attributes }
    assert assigns(:board).rank.positive? && assigns(:board).rank <= Board.count
    assigns(:board).destroy
  end

  test 'should show board' do
    get :show, params: { id: @board.id }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @board.id }
    assert_response :success
  end

  test 'should update board' do
    put :update, params: { id: @board.id, board: { friendly_name: 'updated friendly name' } }
    assert_redirected_to board_path(assigns(:board))
    assert_equal 'updated friendly name', @board.reload.friendly_name
  end

  test 'should destroy board' do
    assert_difference('Board.count', -1) do
      delete :destroy, params: { id: @board.id }
    end

    assert_redirected_to boards_path
  end
end
