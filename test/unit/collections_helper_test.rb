require 'test_helper'
require 'collections_helper'

class CollectionsHelperTest < ActiveSupport::TestCase
  
  context "collections tests" do
    setup do
    end
    
    teardown do
    end

    should "return id for a Topic" do
      expected = "org.perseids.test/Topic/MockClass/aaa"
      assert_equal expected, CollectionsHelper::pid_for(Topic.new("aaa"),"MockClass")
    end

    should "return id without a datatype" do
      mock_obj = stub("mockobj")
      mock_obj.stubs(:id).returns("mockid")
      expected = "org.perseids.test/Mocha::Mock/mockid"
      assert_equal expected, CollectionsHelper::pid_for(mock_obj)
    end

    should "use member pid" do
      mock_obj = stub("mockobj")
      mock_obj.stubs(:id).returns("mockid")
      mock_obj.stubs(:pid).returns("urn:my:mockid")
      assert_equal "urn:my:mockid", CollectionsHelper::member_id_for(mock_obj)
    end

    should "make member pid" do
      mock_obj = stub("mockobj")
      mock_obj.stubs(:id).returns("mockid")
      mock_obj.stubs(:pid).returns(nil)
      assert_equal CollectionsHelper::pid_for(mock_obj), CollectionsHelper::member_id_for(mock_obj)
    end

    context "collections mock tests" do
      setup do
        mock_response = stub("mockresponse")
        mock_collection_api = stub("mockcollectionapi")
        mock_collection_api.stubs(:collections_id_get).raises(CollectionsClient::ApiError)
        mock_collection_api.stubs(:collections_post).returns(mock_response)
        CollectionsHelper.stubs(:get_collections_api).returns(mock_collection_api)
      end

      teardown do
      end

      should "create a collection if missing" do
        mock_pub = stub("mockpub")
        mock_pub.stubs(:id).returns('dummypub')
        mock_pub.stubs(:title).returns("Dummy Publication")
        created = CollectionsHelper::get_collection(mock_pub,true)
        assert_equal "org.perseids.test/Mocha::Mock/dummypub", created 
      end

      should "not create a collection if missing" do
        mock_pub = stub("mockpub")
        mock_pub.stubs(:id).returns('dummypub')
        mock_pub.stubs(:title).returns("Dummy Publication")
        created = CollectionsHelper::get_collection(mock_pub,false)
        assert_nil created 
      end

    end

    should "add to a collection" do 
      mock_pub = stub("mockpub")
      mock_pub.stubs(:id).returns('dummypub')
      mock_pub.stubs(:title).returns("Dummy Publication")
      mock_owner = stub("mockowner")
      mock_owner.stubs(:id).returns('dummyuser')
      mock_owner.stubs(:uri).returns('http://sosol.perseids.org/users/dummyuser')
      mock_owner.stubs(:full_name).returns("Dummy User")
      mock_topics = [ 'dummytopica', 'dummytopicb' ] 
      mock_identifier = stub("mockidentifier")
      mock_identifier.stubs(:id).returns('dummyidentifier')
      mock_identifier.stubs(:mimetype).returns('application/xml')
      mock_identifier.stubs(:pid).returns('urn:cite:perseus:test123.1')
      # skip the tests if the configuration calls for that
      unless CollectionsHelper::get_api_instance().nil? 
        CollectionsHelper::delete_collection(CollectionsHelper::pid_for(mock_pub))
        pub_collection = CollectionsHelper::get_collection(mock_pub, true)
        assert_not_nil(pub_collection)
        CollectionsHelper::put_to_collection(pub_collection, mock_identifier)
        contents = CollectionsHelper::get_collection_members(pub_collection)
        assert_equal 1, contents.size
        assert_equal mock_identifier.pid(), contents[0].id
        CollectionsHelper::delete_from_collection(pub_collection,mock_identifier.pid())
        CollectionsHelper::delete_collection(pub_collection)
        assert_nil CollectionsHelper::get_collection(mock_pub, false)
      end
    end
    
  end
end
