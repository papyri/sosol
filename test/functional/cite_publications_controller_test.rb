require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class CitePublicationsControllerTest < ActionController::TestCase
    def setup
      @user = FactoryGirl.create(:user)
      @request.session[:user_id] = @user.id
        # use a mock Google agent so test doesn't depend upon live google doc
        # test document should produce 9 annotations (from 6 entries in the spreadsheet)
        @client = stub("googless")
        @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), 'data', 'google1.xml')))
        @client.stubs(:get_transformation).returns("/data/xslt/cite/gs_to_oa_cite.xsl")
        AgentHelper.stubs(:get_client).returns(@client)
    end
    
    def teardown
      @request.session[:user_id] = nil
      @user.destroy
    end
    
    def test_should_make_new_object
      get :create_from_linked_urn, :urn => "urn:cite:perseus:pdlcomm",
        :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :type => 'Commentary'
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
    end

    def test_should_warn_collection_changed
      get :create_from_linked_urn, :urn => "urn:cite:perseus:mythcomm",
        :init_value => ["http://data.perseus.org/citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415"], :type => 'Commentary'
      assert_not_nil assigns(:publication)
      assert_not_nil assigns(:identifier)
      assert_equal 'Publication was successfully created.', flash[:notice]
      assert_equal "The requested CITE collection for this Publication is not available. It has been placed in the defaullt collection for it's type",
        flash[:warning]
    end

    def test_should_flash_error_if_deprecated_version_urn_feature_used
      get :create_from_linked_urn, :urn => "urn:cite:perseus:lattb.1.1", :type => 'Treebank' 
      assert_not_nil assigns(:publication)
      assert_nil assigns(:identifier)
      assert_equal 'Creating a new version of an existing CITE object is no longer supported via this method', flash[:error]
    end
    
    #TODO
    # test_should_use_supplied_title
    # test_should_use_temporary_title

     # TODO IMPORT SCENARIOS
     #should "new_from_template works with gss key pub url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end
      #should "new_from_template works with gss key link url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end
      #should "new_from_template work with gss pub url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end

      #should "new_from_template should work with gss link url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/edit?usp=sharing"]
      #  test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #  assert_not_nil test
      #  assert_equal 9, test.get_annotations().size
      #end

      #should "new_from_template raises error with invalid google url as init_value" do
      #  init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc"]
      #  @client.stubs(:get_content).raises("Invalid URL")
      #  exception = assert_raises(RuntimeError) {
      #    test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      #

  end
end
