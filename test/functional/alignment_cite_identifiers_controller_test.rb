require 'test_helper'

class AlignmentCiteIdentifiersControllerTest < ActionController::TestCase

  setup do
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
    assert_select 'ul.sentence_list' do
      assert_select 'li.sentence' do
        assert_select 'a' do
          assert_select 'span.word'
        end
      end
    end
  end

  should "display preview" do
    get :preview, :id => @identifier.id.to_s
    assert_response :success
    assert_select 'ul.sentence_list' do
      assert_select 'li.sentence' do
        assert_select "a[href*=viewer]" do
          assert_select 'span.word'
        end
      end
    end
  end

  should "display edit title" do

  end

  should "update title" do

  end

  should "display editxml" do

  end

  should "destroy" do

  end

  should "not destroy last identifier" do

  end

end