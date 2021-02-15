require 'test_helper'

class DecreesControllerTest < ActionController::TestCase
  def setup
    @admin = FactoryBot.create(:admin)
    @request.session[:user_id] = @admin.id
    @board = FactoryBot.create(:board)
    @decree = FactoryBot.create(:decree, :board => @board)
    @decree_two = FactoryBot.create(:decree, :board => @board)
  end
  
  def teardown
    @admin.destroy
    @decree.destroy
    @decree_two.destroy
    @board.destroy
  end
  
  test "should get index" do
    get :index, params: {}
    assert_response :success
    assert_not_nil assigns(:decrees)
  end

  test "should get new" do
    get :new, params: { :board_id => @board.id }
    assert_response :success
  end

  test "should create decree" do
    assert_difference('Decree.count') do
      post :create, params: { :decree =>
        { :board_id => @board.id,
          :tally_method => Decree::TALLY_METHODS[:count] } }
    end

    assert_redirected_to edit_board_path(@board.id)
  end

  test "should show decree" do
    get :show, params: { :id => @decree.id }
    assert_response :success
  end

  test "should get edit" do
    get :edit, params: { :id => @decree.id }
    assert_response :success
  end

  test "should update decree" do
    put :update, params: { :id => @decree.id, :decree => { tally_method: Decree::TALLY_METHODS[:percent] } }
    assert_redirected_to edit_board_path(@board.id)
    assert_equal Decree::TALLY_METHODS[:percent], @decree.reload.tally_method
  end

  test "should destroy decree" do
    assert_difference('Decree.count', -1) do
      delete :destroy, params: { :id => @decree.id }
    end

    assert_redirected_to edit_board_path(@board.id)
  end
end
