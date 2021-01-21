require 'test_helper'

class DecreesControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryGirl.create(:admin)
    @request.session[:user_id] = @admin.id
    @board = FactoryGirl.create(:board)
    @decree = FactoryGirl.create(:decree, :board => @board)
    @decree_two = FactoryGirl.create(:decree, :board => @board)
  end
  
  def teardown
    @admin.destroy
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
      post :create, :decree => 
        { :board_id => @board.id,
          :tally_method => Decree::TALLY_METHODS[:count] }
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
    assert_redirected_to edit_board_path(@board.id)
  end

  test "should destroy decree" do
    assert_difference('Decree.count', -1) do
      delete :destroy, :id => @decree.id
    end

    assert_redirected_to edit_board_path(@board.id)
  end
end
