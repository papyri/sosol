require 'test_helper'

class DecreesControllerTest < ActionController::TestCase
  def setup
    @board = Factory(:board)
    @decree = Factory(:decree, :board => @board)
    @decree_two = Factory(:decree, :board => @board)
  end
  
  def teardown
    @decree.destroy
    @decree_two.destroy
    @board.destroy
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:decrees)
  end

  test "should get new" do
    get :new, { :board_id => @board.id }
    assert_response :success
  end

  test "should create decree" do
    assert_difference('Decree.count') do
      post :create, :decree => { :board_id => @board.id }
    end

    assert_redirected_to edit_board_path(@board.id)
  end

  test "should show decree" do
    get :show, :id => @decree.id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @decree.id
    assert_response :success
  end

  test "should update decree" do
    put :update, :id => @decree.id, :decree => { }
    assert_redirected_to decree_path(assigns(:decree))
  end

  test "should destroy decree" do
    assert_difference('Decree.count', -1) do
      delete :destroy, :id => @decree.id
    end

    assert_redirected_to decrees_path
  end
end
