require 'test_helper'

class BoardsControllerTest < ActionController::TestCase

  context "as admin" do
    setup do
      @admin = FactoryGirl.create(:admin)
      @request.session[:user_id] = @admin.id
      @board = FactoryGirl.create(:board)
      @board_two = FactoryGirl.create(:board)
      @community_board = FactoryGirl.create(:community_board)
      Sosol::Application.config.allow_canonical_boards = true
    end

    teardown do
      @request.session[:user_id] = nil
      @admin.destroy
      Sosol::Application.config.allow_canonical_boards = true
      @board.destroy unless !Board.exists? @board.id
      @board_two.destroy unless !Board.exists? @board_two.id
      @community_board.destroy unless !Board.exists? @community_board.id
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:boards)
      assert_equal [@board, @board_two], assigns(:boards)['No Community']
      assert_equal [@community_board], assigns(:boards)[@community_board.community.friendly_name]
    end

    should "get index and obey allow_canonical_boards" do
      Sosol::Application.config.allow_canonical_boards = false
      get :index
      assert_response :success
      assert_not_nil assigns(:boards)
      assert_nil assigns(:boards)['No Community']
      assert_equal [@community_board], assigns(:boards)[@community_board.community.friendly_name]
      Sosol::Application.config.allow_canonical_boards = true
    end

    should "get new" do
      get :new
      assert_response :success
    end

    should "create board" do
      assert_difference('Board.count') do
        post :create, :board => FactoryGirl.build(:board).attributes
      end

      assert_redirected_to edit_board_path(assigns(:board))
      assigns(:board).destroy
    end

    should "have max rank default" do
      post :create, :board => FactoryGirl.build(:board).attributes
      assert assigns(:board).rank == Board.where(:community_id => nil).count, "Expected #{assigns(:board).rank} to equal #{Board.where(:community_id => nil).count}"
      assigns(:board).destroy
    end


    should "community board should have max rank default" do
      post :create, :board => FactoryGirl.build(:community_board).attributes
      assert assigns(:board).rank == assigns(:board).community.boards.count
      assigns(:board).destroy
    end

    should "have valid rank" do
      post :create, :board => FactoryGirl.build(:board).attributes
      assert assigns(:board).rank > 0 && assigns(:board).rank <= Board.count
      assigns(:board).destroy
    end

    should "community board should have valid rank" do
      post :create, :board => FactoryGirl.build(:community_board).attributes
      assert assigns(:board).rank > 0 && assigns(:board).rank <= assigns(:board).community.boards.count
      assigns(:board).destroy
    end

    should "show non community boards by rank" do
      get :rank
      assert assigns(:boards)
      assert_equal [ @board, @board_two ], assigns(:boards)
      assert_equal "", assigns(:community_id)
    end

    should "show community boards by rank" do
      get :rank, :community_id => @community_board.community.id
      assert assigns(:boards)
      assert_equal [ @community_board ], assigns(:boards)
      assert_equal @community_board.community.id.to_s, assigns(:community_id)
    end

    should "show board" do
      get :show, :id => @board.id
      assert_response :success
    end

    should "get edit" do
      get :edit, :id => @board.id
      assert_response :success
    end

    should "update board" do
      put :update, :id => @board.id, :board => { }
      assert_redirected_to board_path(assigns(:board))
    end

    should "destroy board" do
      assert_difference('Board.count', -1) do
        delete :destroy, :id => @board.id
      end

      assert_redirected_to boards_path
    end

    should "confirm apply rules" do 
      get :confirm_apply_rules, :id => @board.id
      assert_response :success
    end

    should "apply rules" do 
      post :apply_rules, :id => @board.id
      assert_redirected_to :controller => :user, :action => :board_dashboard, :board_id => @board.id
    end

  end

  context "as non-admin" do

    setup do
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @board = FactoryGirl.create(:board)
    end

    teardown do
      @request.session[:user_id] = nil
      @user.destroy
      @board.destroy
    end

    should "not get new" do
      get :new
      assert_response 403
    end

    should "not get index" do
      get :index
      assert_response 403
    end

    should "not create board" do
      assert_difference('Board.count',0) do
        post :create, :board => FactoryGirl.build(:board).attributes
      end
      assert_response 403
    end

    should "not allow rank" do
      get :rank
      assert_response 403
    end

    should "not show board" do
      get :show, :id => @board.id
      assert_response 403
    end

    should "not get edit" do
      get :edit, :id => @board.id
      assert_response 403
    end

    should "not update board" do
      put :update, :id => @board.id, :board => { }
      assert_response 403
    end

    should "not destroy board" do
      assert_difference('Board.count', 0) do
        delete :destroy, :id => @board.id
      end
      assert_response 403
    end

    should "not confirm apply rules" do 
      get :confirm_apply_rules, :id => @board.id
      assert_response 403
    end

    should "not apply rules" do 
      post :apply_rules, :id => @board.id
      assert_response 403
    end

    should "not find finalizer" do 
      get :find_member_finalizer, :id => @board.id
      assert_response 403
    end

    should "not set finalizer" do 
      get :set_member_finalizer, :id => @board.id, :user_id => @user.id, :user_name => @user.name
      assert_response 403
    end

    should "not remove finalizer" do 
      get :remove_member_finalizer, :id => @board.id
      assert_response 403
    end

  end

  context "as community-admin" do

    setup do
      @user = FactoryGirl.create(:user)
      @member = FactoryGirl.create(:user)
      @other_user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      Sosol::Application.config.allow_canonical_boards = true
      @board = FactoryGirl.create(:board)
      @community_board = FactoryGirl.create(:community_board)
      @community_board.community.admins = [@user]
      @community_board.users << @member
    end

    teardown do
      @request.session[:user_id] = nil
      @user.destroy
      @community_board.destroy
      @board.destroy
    end

    should "not get new" do
      get :new
      assert_response 403
    end

    should "not get index" do
      get :index
      assert_response 403
    end

    should "not create board" do
      assert_difference('Board.count',0) do
        post :create, :board => FactoryGirl.build(:board).attributes
      end
      assert_response 403
    end

    should "not allow rank" do
      get :rank
      assert_response 403
    end

    should "not show non-community board" do
      get :show, :id => @board.id
      assert_response 403
    end

    should "show community board" do
      get :show, :id => @community_board.id
      assert_response :success
    end

    should "not get edit for non community board" do
      get :edit, :id => @board.id
      assert_response 403
    end

    should "get edit for community board" do
      get :edit, :id => @community_board.id
      assert_response :success
    end

    should "not update non community board" do
      put :update, :id => @board.id, :board => { }
      assert_response 403
    end

    should "update community board" do
      put :update, :id => @community_board.id, :board => { }
      assert_redirected_to board_path(assigns(:board))
    end

    should "not destroy board" do
      assert_difference('Board.count', 0) do
        delete :destroy, :id => @board.id
      end
      assert_response 403
      assert_difference('Board.count', 0) do
        delete :destroy, :id => @community_board.id
      end
      assert_response 403
    end

    should "not confirm apply rules to non-community board" do 
      get :confirm_apply_rules, :id => @board.id
      assert_response 403
    end

    should "not apply rules to non-community board" do 
      post :apply_rules, :id => @board.id
      assert_response 403
    end

    should "confirm apply rules to community board" do 
      get :confirm_apply_rules, :id => @community_board.id
      assert_response :success
    end

    should "apply rules to community board" do 
      post :apply_rules, :id => @community_board.id
      assert_redirected_to :controller => :user, :action => :board_dashboard, :board_id => @community_board.id
    end

    should "show only members to set as finalizer" do 
      get :find_member_finalizer, :id => @community_board.id
      assert_select 'li.select_user_name', 1
      assert_select 'li.select_user_name a', text: "#{@member.human_name} (#{@member.name})"
    end

    should "set only members as finalizer" do 
      get :set_member_finalizer, :id => @community_board.id, :user_name => @other_user.name, :user_id => @other_user.id
      assert_equal "User #{@other_user.name} is not a member of this board.", flash[:error]
      assert_nil @community_board.finalizer_user
      get :set_member_finalizer, :id => @community_board.id, :user_name => @member.name, :user_id => @member.id
      assert_equal "Default finalizer updated to #{@member.name}.", flash[:notice]
      @community_board.reload
      assert_equal @member, @community_board.finalizer_user
    end

    should "remove member as finalizer when removing member" do
      get :set_member_finalizer, :id => @community_board.id, :user_name => @member.name, :user_id => @member.id
      @community_board.reload
      assert_equal @member, @community_board.finalizer_user
      get :remove_member, :id => @community_board.id, :user_id => @member.id
      @community_board.reload
      assert_equal 0, @community_board.users.size
      assert_nil @community_board.finalizer_user
    end
  end
end
