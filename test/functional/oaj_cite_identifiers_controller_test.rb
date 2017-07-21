require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('OaCiteIdentifier')
  class OajCiteIdentifiersControllerTest < ActionController::TestCase
    def setup
      ApplicationController::prepend_view_path 'app/views_perseids'
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
      @publication = FactoryGirl.create(:publication, :owner => @user, :creator => @user, :status => "new")
      @publication.branch_from_master
      @valid_oaj = File.read(File.join(File.dirname(__FILE__), 'data', 'validoaj.json'))
      @identifier = OajCiteIdentifier.new_from_supplied(@publication,"urn:cite:perseus:pdlann.1.1",@valid_oaj,"testing")
    end

    def teardown
      @identifier.destroy unless @identifier.nil?
      @publication.destroy unless @publication.nil?
      @user.destroy unless @publication.nil?
    end

    test "edit view" do
      get :edit, :id => @identifier.id
      assert_response(:success)
      assert_select 'textarea'
    end

    test "show preview" do
      get :preview, :id => @identifier.id
      assert_response(:success)
      assert_select 'pre'
    end

    test "update fails with invalid data" do
      post :update, :id => @identifier.id, :oaj_cite_identifier => {:xml_content => 'bad data' }
      assert_redirected_to edit_publication_oaj_cite_identifier_path( @publication, @identifier )
    end

    test "update succeeds with valid data" do
      post :update, :id => @identifier.id, :oaj_cite_identifier => {:xml_content => @valid_oaj }
      assert_redirected_to edit_publication_oaj_cite_identifier_path( @publication, @identifier )
    end
  end
end
