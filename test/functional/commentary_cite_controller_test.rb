require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CommentaryCiteIdentifier')
  class CommentaryCiteIdentifiersControllerTest < ActionController::TestCase
    def setup
      ApplicationController::prepend_view_path 'app/views_perseids'
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new",
        :title => "Commentary Pub1")
      @publication.branch_from_master
      @publication2 = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new",
        :title => "Commentary Pub2")
      @publication2.branch_from_master
      @identifier = CommentaryCiteIdentifier.new_from_template(@publication2)

    end

    def teardown
      unless @identifier.nil?
        @identifier.destroy
      end
      unless @publication.nil?
        @publication.destroy
      end
      unless @publication2.nil?
        @publication2.destroy
      end
      @request.session[:user_id] = nil
      @user.destroy
    end


    should "create from annotation" do
      get :create_from_annotation, :publication_id => @publication.id.to_s,
        :init_value => ["urn:cts:greekLit:tlg0012.tlg001:1.1"]
      assert_not_nil assigns(:identifier)
      assert_equal ["urn:cts:greekLit:tlg0012.tlg001:1.1"], assigns(:identifier).get_targets()
      assert_equal "", assigns(:identifier).get_commentary_text()
      assert_equal "eng", assigns(:identifier).language()
    end

    should "create" do
      post :create, :publication_id => @publication.id.to_s,
        :init_value => ["urn:cts:greekLit:tlg0012.tlg001:1.1"]
      assert_not_nil assigns(:identifier)
      assert_equal ["urn:cts:greekLit:tlg0012.tlg001:1.1"], assigns(:identifier).get_targets()
      assert_equal "", assigns(:identifier).get_commentary_text()
      assert_equal "eng", assigns(:identifier).language()
    end

    should "display edit" do
      @identifier.update_targets(["urn:cts:greekLit:tlg0012.tlg001:1.1"],"test")
      @identifier.reload
      get :edit, :publication_id => @publication2.id.to_s, :id => @identifier.id.to_s
      assert_response :success
      assert_select '.targets' do
        assert_select '.oac_target' do
          assert_select 'a[href="urn:cts:greekLit:tlg0012.tlg001:1.1"]'
        end
      end
    end

    should "update" do
      post :update, :publication_id => @publication2.id.to_s, :id => @identifier.id.to_s, :commentary_text => 'my commentary'
      assert_match /File updated/, flash[:notice]
      @identifier.reload
      assert_equal "my commentary", @identifier.get_commentary_text()
      # make sure edit now displays the updated text
      get :edit, :publication_id => @publication2.id.to_s, :id => @identifier.id.to_s
      assert_response :success
      assert_select 'textarea', "my commentary"
    end

    should "display preview" do
      @identifier.update_targets(["urn:cts:greekLit:tlg0012.tlg001:1.1"],"test")
      @identifier.reload
      get :preview, :publication_id => @publication2.id.to_s, :id => @identifier.id.to_s
      assert_response :success
      assert_select '.oac_target' do
        assert_select 'a[href="urn:cts:greekLit:tlg0012.tlg001:1.1"]'
      end
    end
  end
end
