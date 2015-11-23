require 'test_helper'

class UserControllerTest < ActionController::TestCase

  def setup
    @user = FactoryGirl.create(:user)
    @request.session[:user_id] = @user.id
    @branchname = "testpublication"
    @user.repository.create_branch(@branchname)
    @community = FactoryGirl.create(:master_community, :is_default => true, :name => 'sosolmaster')
    @community2 = FactoryGirl.create(:end_user_community, :is_default => false, :name => 'testcommunity')
    @publication = Publication.new_from_templates(@user)
  end

  def teardown
    @request.session[:user_id] = nil
    @user.destroy
    @publication.destroy
    @community.destroy
    @community2.destroy
  end

  test "publications in default community show in dashboard" do
    get :user_dashboard
    assert_select 'table.results' do
      assert_select 'tr', 2
    end
  end

  test "publications in non-default community show only in community dashboard" do
    @publication2 = Publication.new_from_templates(@user)
    @publication2.community_id = @community2.id.to_s
    @publication2.save!

    get :user_dashboard
    assert_select 'table.results' do
      assert_select 'tr', 2
    end

    get :user_community_dashboard, :community_id => @community2.id.to_s
    assert_select 'table.results' do
      assert_select 'tr', 2
    end
  end
end
