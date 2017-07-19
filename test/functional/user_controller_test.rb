require 'test_helper'

class UserControllerTest < ActionController::TestCase

  context "user tests" do

    setup do
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @branchname = "testpublication"
      @user.repository.create_branch(@branchname)
      @community = FactoryGirl.create(:master_community, :is_default => true, :name => 'sosolmaster')
      @community2 = FactoryGirl.create(:end_user_community, :is_default => false, :name => 'testcommunity')
      @publication = Publication.new_from_templates(@user)
    end

    teardown do
      @request.session[:user_id] = nil
      @publication.destroy
      @community.destroy
      @community2.destroy
      @user.destroy
    end

    context "basic tests" do
      should "publications in default community show in dashboard" do
        get :user_dashboard
        assert_not_nil @user
        assert_not_nil @user.repository
        assert_select '.publication', 1
       end

      should "publications in non-default community show only in community dashboard" do
        @publication2 = Publication.new_from_templates(@user)
        @publication2.community_id = @community2.id.to_s
        @publication2.save!

        get :user_dashboard
        assert_select '.publication', 1

        get :user_community_dashboard, :community_id => @community2.id.to_s
        assert_select '.publication', 1

      end

    end
  end

  context "admin level restricted" do

    setup do
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @branchname = "testpublication"
      @user.repository.create_branch(@branchname)
      @community = FactoryGirl.create(:master_community, :is_default => true, :name => 'sosolmaster')
      @community2 = FactoryGirl.create(:end_user_community, :is_default => false, :name => 'testcommunity')
      @publication = Publication.new_from_templates(@user)
      @user2 = FactoryGirl.create(:user)
      @u2publication = Publication.new_from_templates(@user2)
    end

    teardown do
      @request.session[:user_id] = nil
      @publication.destroy
      @u2publication.destroy
      @community.destroy
      @community2.destroy
      @user2.destroy
      @user.destroy
    end

    should "non admin can't list users by email" do
      get :index_users_by_email
      assert_equal "Invalid Access.", flash[:warning]
      assert_redirected_to( :controller => "user", :action => "dashboard" )
    end

    should "non admin can't delete user" do
      get :confirm_delete, :user_id => @user2.id
      assert_equal "Invalid Access.", flash[:warning]
      assert_redirected_to( :controller => "user", :action => "dashboard" )
    end

    should "non admin really can't delete user" do
      username = @user2.name
      get :delete, :user_id => @user2.id
      assert_equal "Invalid Access.", flash[:warning]
      assert_redirected_to( :controller => "user", :action => "dashboard" )
      assert_not_nil @user2
    end

  end

  context "admin level access" do

    setup do
      @user = FactoryGirl.create(:user, :is_master_admin => true)
      @request.session[:user_id] = @user.id
      @branchname = "testpublication"
      @user.repository.create_branch(@branchname)
      @community = FactoryGirl.create(:master_community, :is_default => true, :name => 'sosolmaster')
      @community2 = FactoryGirl.create(:end_user_community, :is_default => false, :name => 'testcommunity')
      @publication = Publication.new_from_templates(@user)
      @user2 = FactoryGirl.create(:user)
      @user2.repository.create_branch(@branchname)
      @u2publication = Publication.new_from_templates(@user2)
    end

    teardown do
      @request.session[:user_id] = nil
      @publication.destroy
      @u2publication.destroy
      @community.destroy
      @community2.destroy
      @user.destroy
      @user2.destroy
    end

    should "admin can list users by email" do
      get :index_users_by_email
      assert_response(:success)
    end

    should "admin can delete user" do
      get :confirm_delete, :user_id => @user2.id
      assert_equal "This user has pending publications which will be destroyed.  Consider downloading a backup first.", flash[:warning]
    end

    should "admin really can delete user" do
      username = @user2.name
      get :delete, :user_id => @user2.id
      assert_equal "Deleted User #{username}", flash[:notice]
      assert_redirected_to( :controller => "user", :action => "dashboard" )
    end

  end
end
