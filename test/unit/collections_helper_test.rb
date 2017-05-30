require 'test_helper'
require 'collections_helper'

class CollectionsHelperTest < ActiveSupport::TestCase
  
  context "collections tests" do
    setup do
    end
    
    teardown do
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
      # skip the tests if the configuration calls for that
      unless CollectionsHelper::get_api_instance().nil? 
        pubcoll = CollectionsHelper::pid_for(mock_pub.id, 'publication')
        CollectionsHelper::delete_collection(pubcoll)
        pub_collection = CollectionsHelper::get_pub_collection(mock_pub, true)
        assert_not_nil(pub_collection)
        CollectionsHelper::put_to_collection(pub_collection, mock_identifier)
     
        usercoll = CollectionsHelper::pid_for(mock_owner.id,mock_owner.class.to_s)
        CollectionsHelper::delete_collection(usercoll)
        user_collection = CollectionsHelper::get_user_collection(mock_owner, true)
        assert_not_nil(user_collection)

        CollectionsHelper::put_to_collection(user_collection, mock_identifier)
        # add it to the subject collections
        mock_topics.each do |c|
          tcoll = CollectionsHelper::pid_for(c,'topic', 'dummyclass')
          CollectionsHelper::delete_collection(tcoll)
          topic_collection = CollectionsHelper::get_topic_collection(c, 'dummyclass', true)
          assert_not_nil(topic_collection)
          CollectionsHelper::put_to_collection(topic_collection, mock_identifier)
        end
        # now delete
        mid = CollectionsHelper::pid_for(mock_identifier.id,mock_identifier.class.to_s)
        CollectionsHelper::delete_from_collection(user_collection,mid)
      end
    end
    
  end
end
