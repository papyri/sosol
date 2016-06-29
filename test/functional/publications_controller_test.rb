require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  def setup
    @user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    @request.session[:user_id] = @user.id
  end

  def teardown
    @request.session[:user_id] = nil
    @user.destroy
    @admin.destroy
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end

  def test_should_create_new_batch
    assert_difference('Publication.count') do
      post :create_from_list,  :pn_id_list => "papyri.info/hgv/3147   papyri.info/hgv/3148  papyri.info/hgv/3149  papyri.info/ddbdp/bgu;7;1520  papyri.info/ddbdp/bgu;7;1521 papyri.info/ddbdp/bgu;7;1522" 
      assert_equal 'Publication was successfully created.', flash[:notice]
    end
    assert_equal 6, assigns(:publication).identifiers.size 
  end

  context "external agent api" do
    setup do
      @agent = stub("mockagent")
      @client = stub("mockclient")
      @client.stubs(:verify_secret?).returns(true)
      @client.stubs(:post_content).returns(201)
      @client.stubs(:get_transformation).returns(nil)
      AgentHelper.stubs(:get_client).returns(@client)
      AgentHelper.stubs(:agent_of).returns(@agent)
      @test_agent_community = FactoryGirl.create(:pass_through_community,
                                           :name => "test_freaky_agent_community",
                                           :friendly_name => "testy agent",
                                           :allows_self_signup => true,
                                           :description => "a comunity for testing",
                                           :pass_to => "mockagent")
      @test_agent_board = FactoryGirl.create(:master_community_board, :title => "MockAgent", :community_id => @test_agent_community.id)
      @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      @ddb_identifier = DDBIdentifier.new_from_template(@publication)
    end

    teardown do
    end

    should "test_agent_failure_callback_should_send_email" do
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        get :agent_failure_callback, :id => @publication.id, :sha => 'TODO', :agent_uri => 'http://example.org/agent'
      end
      assert_response :success
    end

    should "test_agent_failure_callback_should_fail_if_bad_agent" do
      @client.stubs(:verify_secret?).returns(false)
      assert_difference 'ActionMailer::Base.deliveries.size', 0 do
        get :agent_failure_callback, :id => @publication.id, :sha => 'TODO', :agent_uri => 'http://example.org/agent'
      end
      assert_response :error
    end

    should "send_to_agent" do
      # just mock the status of the pub for the purposes of the test
      @publication.community = @test_agent_community
      @publication.status = 'finalized'
      @publication.save
      @publication.reload
      get :send_to_agent, :id => @publication.id
      assert_response :redirect
      assert_equal "Publication resent to agent.", flash[:notice]
    end

    should "fail_send_to_agent_not_passthrough" do
      get :send_to_agent, :id => @publication.id
      assert_response :redirect
      assert_equal "This publication is not owned by a passthrough community", flash[:error]
    end

    should "fail_send_to_agent_not_finalized" do
      @publication.community = @test_agent_community
      @publication.save
      @publication.reload
      get :send_to_agent, :id => @publication.id
      assert_response :redirect
      assert_equal "Publication does not meet the conditions for sending.", flash[:error]
    end
  end
end
