require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('AlignmentCiteIdentifier')
  class AlignmentCiteIdentifiersControllerTest < ActionController::TestCase

    setup do
      ApplicationController::prepend_view_path 'app/views_perseids'
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
      @publication.branch_from_master
      file = File.read(File.join(File.dirname(__FILE__), 'data', 'validalign.xml'))
      @identifier = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
    end

    teardown do
      @identifier.destroy unless @identifier.nil?
      @publication.destroy unless @publication.nil?
      @user.destroy
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
      post :update_title, :id => @identifier.id.to_s, :alignment_cite_identifier => {:title => 'TestTitle'}
      @identifier.reload
      assert @identifier.title == 'TestTitle'
      assert_equal "Title was successfully updated.", flash[:notice]
      assert_redirected_to :controller => :alignment_cite_identifiers, :action => :edit, :id => @identifier.id.to_s
    end

    should "display editxml" do
      get :editxml, :id => @identifier.id.to_s
      assert_response :success
      assert_select 'input[type=text]'
    end

    should "updatexml" do
      content = { :xml_content => @identifier.xml_content.sub("Automatic","Test") }
      get :editxml, :id => @identifier.id.to_s, :publication_id => @identifier.publication.id.to_s
      put :updatexml, :id => @identifier.id.to_s , :publication_id => @identifier.publication.id.to_s,  :comment => "test", :alignment_cite_identifier => content
      assert_match "File updated", flash[:notice]
      @identifier.reload
      assert_match /Test Alignment/, @identifier.content
      assert_redirected_to editxml_publication_alignment_cite_identifier_path(@publication,@identifier)
    end

    should "destroy" do
      assert_difference('AlignmentCiteIdentifier.count',-1) do
        # add another identifier of a different type so we can test destroy
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'updatetb.xml'))
        tb = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert_not_nil tb
        delete :destroy, :id => @identifier.id
      end
    end

    should "not destroy last identifier" do
      assert_difference('AlignmentCiteIdentifier.count',0) do
        delete :destroy, :id => @identifier.id
      end
      assert_equal "This would leave the publication without any identifiers.", flash[:error]
    end

  end
end
