require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('CiteIdentifier')
  class CitePublicationsControllerTest < ActionController::TestCase
    def setup
      ApplicationController::prepend_view_path 'app/views_perseids'
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
    end
    
    def teardown
      @request.session[:user_id] = nil
      @user.destroy
    end
    
    def test_should_make_new_object
      get :create_from_linked_urn, :urn => "urn:cite:perseus:pdlcomm",
        :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :identifier_type => 'Commentary'
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
    end

    def test_should_warn_collection_changed
      get :create_from_linked_urn, :urn => "urn:cite:perseus:mythcomm",
        :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :identifier_type => 'Commentary'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_equal "The requested CITE collection for this Publication is not available. It has been placed in the defaullt collection for it's type",
        flash[:warning]
    end

    def test_should_flash_error_if_deprecated_version_urn_feature_used
      get :create_from_linked_urn, :urn => "urn:cite:perseus:lattb.1.1", :identifier_type => 'Treebank'
      assert_nil assigns(:publication)
      assert_nil assigns(:identifier)
      assert_equal 'Creating a new version of an existing CITE object is no longer supported via this method', flash[:error]
    end



    context "with stubbed url agent" do

      setup do
        ApplicationController::prepend_view_path 'app/views_perseids'
        @client = stub("url")
        @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), 'data', 'updatetb.xml')))
        AgentHelper.stubs(:get_client).returns(@client)
      end

      teardown do
      end

      should "create_from_linked_urn_with_treebank_template_url" do
        get :create_from_linked_urn, :init_value => ["https://example.org/mytemplate.xml"], :identifier_type => 'Treebank'
        assert_not_nil assigns(:publication)
        assert_not_nil assigns(:identifier)
        assert_equal 'Publication was successfully created.', flash[:notice]
        assert_redirected_to edit_publication_treebank_cite_identifier_path(assigns(:publication), assigns(:identifier))
      end

      should "not_create_from_linked_urn_with_bad_treebank_template_data" do
        @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), 'data', 'badtb.xml')))
        get :create_from_linked_urn, :init_value => ["https://example.org/mytemplate.xml"], :identifier_type => 'Treebank'
        assert_match /Error creating publication/, flash[:error]
        assert_redirected_to dashboard_url
      end

     should "user_collection_list shows treebank item" do
        # create an item in a collection
        get :create_from_linked_urn, :init_value => ["https://example.org/mytemplate.xml"], :identifier_type => 'Treebank'
        assert_not_nil assigns(:identifier)
        @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), 'data', 'tb3.xml')))
        get :create_from_linked_urn, :init_value => ["https://example.org/mytemplate.xml"], :identifier_type => 'Treebank'
        assert_not_nil assigns(:identifier)
        # see that it's returned in the user collection list
        get :user_collection_list, :item_match => "urn:cts:latinLit:tg.work2.edition", :collection => "urn:cite:perseus:lattb"
        assert_response :success
        assert_select 'div.cite_list' do
          assert_select 'ul' do
            assert_select 'li', 1
          end
        end

      end

     should "user_collection_list doesn't show item" do
        # create an item in a collection
        get :create_from_linked_urn, :init_value => ["https://example.org/mytemplate.xml"], :identifier_type => 'Treebank'
        assert_not_nil assigns(:identifier)
        # request a different collection, returns no items
        get :user_collection_list, :item_match => "urn:cts:latinLit:tg.work.edition", :collection => "urn:cite:perseus:grctb"
        assert_response :success
        assert_equal "No matching publications found!", flash[:notice]
        # request a different urn target, returns no items
        get :user_collection_list, :item_match => "urn:cts:latinLit:tg.workbad.edition", :collection => "urn:cite:perseus:lattb"
        assert_response :success
        assert_equal "No matching publications found!", flash[:notice]
      end

    end

    context "with stubbed googless agent" do
      setup do
        ApplicationController::prepend_view_path 'app/views_perseids'
        # use a mock Google agent so test doesn't depend upon live google doc
        # test document should produce 9 annotations (from 6 entries in the spreadsheet)
        @client = stub("googless")
        @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), 'data', 'google1.xml')))
        @client.stubs(:get_transformation).returns("/data/xslt/cite/gs_to_oa_cite.xsl")
        AgentHelper.stubs(:get_client).returns(@client)
      end

      teardown do
      end

        should "create_from_linked_urn with gss key pub url as init_value" do
          init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
          get :create_from_linked_urn, :init_value => init_value,  :identifier_type => 'Oa'
          assert_not_nil assigns(:publication)
          assert_not_nil assigns(:identifier)
          assert_equal 9, assigns(:identifier).get_annotations().size
          assert_equal 'Publication was successfully created.', flash[:notice]
          assert_redirected_to edit_publication_oa_cite_identifier_path(assigns(:publication), assigns(:identifier))
        end

        should "create_from_linked_urn with gss key link url as init_value" do
          init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
          get :create_from_linked_urn, :init_value => init_value,  :identifier_type => 'Oa'
          assert_not_nil assigns(:publication)
          assert_not_nil assigns(:identifier)
          assert_equal 9, assigns(:identifier).get_annotations().size
          assert_equal 'Publication was successfully created.', flash[:notice]
          assert_redirected_to edit_publication_oa_cite_identifier_path(assigns(:publication), assigns(:identifier))
        end

        should "create_from_linked_urn with gss pub url as init_value" do
          init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
          get :create_from_linked_urn, :init_value => init_value,  :identifier_type => 'Oa'
          assert_not_nil assigns(:publication)
          assert_not_nil assigns(:identifier)
          assert_equal 9, assigns(:identifier).get_annotations().size
          assert_equal 'Publication was successfully created.', flash[:notice]
          assert_redirected_to edit_publication_oa_cite_identifier_path(assigns(:publication), assigns(:identifier))
        end

        should "create_from_linked_urn with gss link url as init_value" do
          init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/edit?usp=sharing"]
          get :create_from_linked_urn, :init_value => init_value,  :identifier_type => 'Oa'
          assert_not_nil assigns(:publication)
          assert_not_nil assigns(:identifier)
          assert_equal 9, assigns(:identifier).get_annotations().size
          assert_equal 'Publication was successfully created.', flash[:notice]
          assert_redirected_to edit_publication_oa_cite_identifier_path(assigns(:publication), assigns(:identifier))
        end

        should "create_from_linked_urn fails with invalid google url as init_value" do
          init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc"]
          @client.stubs(:get_content).raises("Invalid URL")
          get :create_from_linked_urn, :init_value => init_value,  :identifier_type => 'Oa'
          assert_match /Error creating publication/, flash[:error]
          assert_redirected_to dashboard_url
        end

    end

  end
end
