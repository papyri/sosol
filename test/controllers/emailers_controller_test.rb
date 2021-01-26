require 'test_helper'

class EmailersControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryBot.create(:admin)
    @request.session[:user_id] = @admin.id
    @board = FactoryBot.create(:board)
    @emailer = FactoryBot.create(:emailer, :board => @board)
    @emailer_two = FactoryBot.create(:emailer, :board => @board)
  end
  
  def teardown
    @admin.destroy
    @emailer.destroy
    @emailer_two.destroy
    @board.destroy
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:emailers)
  end

  test "should get new" do
    get :new, { :board_id => @board.id }
    assert_response :success
  end

  test "should create emailer" do
    assert_difference('Emailer.count') do
      post :create, :emailer => { :board_id => @board.id }
    end

    assert_redirected_to edit_emailer_path(@board.emailers.last.id)
  end

  test "should show emailer" do
    get :show, :id => @emailer.id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @emailer.id
    assert_response :success
  end

  test "should update emailer" do
    put :update, :id => @emailer.id, :emailer => { }
    assert_redirected_to edit_board_path(@emailer.board.id)
  end

  test "should destroy emailer" do
    assert_difference('Emailer.count', -1) do
      delete :destroy, :id => @emailer.id
    end

    assert_redirected_to edit_board_path(@emailer.board.id)
  end
end
