require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class TreebankCiteIdentifiersControllerTest < ActionController::TestCase
    setup do
      ApplicationController::prepend_view_path 'app/views_perseids'
      @user = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
      @publication.branch_from_master
      file = File.read(File.join(File.dirname(__FILE__), 'data', 'tb3.xml'))
      @identifier = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
      @publication2 = FactoryGirl.create(:publication, :owner => @user2, :creator => @user2, :status => "new", :title=> "t2")
      @publication2.branch_from_master
      @identifier2 = TreebankCiteIdentifier.new_from_supplied(@publication2,"http://testapp",file,"apicreate")
    end

    teardown do
      @identifier.destroy unless @identifier.nil?
      @identifier2.destroy unless @identifier2.nil?
      @publication.destroy unless @publication.nil?
      @publication2.destroy unless @publication2.nil?
      @user.destroy
      @user2.destroy
    end

    should "display edit" do
      get :edit, :id => @identifier.id.to_s
      assert_response :success
      assert_select 'li.sentence' do
        assert_select 'a' do
          assert_select 'span.word'
        end
      end
    end

    should "display preview" do
      get :preview, :id => @identifier.id.to_s
      assert_response :success
      assert_select 'li.sentence' do
        assert_select "a[href*=viewer]" do
          assert_select 'span.word'
        end
      end
    end

    should "display edit title" do
      get :edit_title, :id => @identifier.id.to_s
      assert_response :success
      assert_select 'input[type=text]'
    end

    should "update title" do
      post :update_title, :id => @identifier.id.to_s, :treebank_cite_identifier => {:title => 'TestTitle'}
      @identifier.reload
      assert @identifier.title == 'TestTitle'
      assert_equal "Title was successfully updated.", flash[:notice]
      assert_redirected_to :controller => :treebank_cite_identifiers, :action => :edit, :id => @identifier.id.to_s
    end

    should "display editxml" do
      get :editxml, :id => @identifier.id.to_s
      assert_response :success
      assert_select 'input[type=text]'
    end

    should "updatexml" do
      content = { :xml_content => @identifier.xml_content.sub("aldt","testformat") }
      get :editxml, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
      put :updatexml, :id => @identifier.id.to_s , :publication_id => @identifier.publication.id.to_s,
        :comment => "test", :treebank_cite_identifier => content
      assert_match "File updated", flash[:notice]
      @identifier.reload
      assert_match /testformat/, @identifier.content
      assert_redirected_to editxml_publication_treebank_cite_identifier_path(@publication,@identifier)
    end

    should "display review" do
      get :review, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
      assert_response :success
      assert_select 'li.sentence' do
        assert_select "a[href*=gold=100]" do
          assert_select 'span.word'
        end
      end
    end

    should "list comparable files" do
      # compare the other user's file to my own
      get :compare, :id => @identifier2.id.to_s, :publication_id => @publication2.id.to_s
      assert_response :success
      assert_select '#compare' do
        assert_select 'ol' do
          assert_select 'li' do
            assert_select "a[href*=gold=#{@identifier.id.to_s}]"
          end
        end
      end
    end
  end
end
