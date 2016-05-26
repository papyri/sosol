require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class TreebankCiteIdentifierTest < ActiveSupport::TestCase
    
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
        # branch from master so we aren't just creating an empty branch

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      
      end
      
      teardown do
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end
         
      should "match_on_url" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'bobstb1.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["http://bobsfiles.com/1.xml"])
      end

      should "match_on_url_urn" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
      end

      should "match_on_url_urn_with_urn" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
      end

      should "match_on_url_urn_with_urn_no_range" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurlnorange.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
        assert ! test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.2"])
      end

      # this test is failing - the cts lib is doing something weird with the xml
      # bit -- reenable test when we upgrade to CTS 5
      #should "not_match_on_url_urn_with_extension" do
      #  file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
      #  test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
      #  assert ! test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1.xml"])
      #end
       should "parse annotation targets" do
         file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
         test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
         expected = {
           'aggregates' => [ {'uri' => "urn:cts:latinLit:phi1221.phi007.perseus-lat1", 'mediatype' => 'text/xml'}],
           'annotations'=> [
           {"about"=>["urn:cts:latinLit:phi1221.phi007.perseus-lat1:appendix"],
            "query"=>"s=1",
            "dc:format"=>"http://data.perseus.org/rdfvocab/treebank"},
           {"about"=>["urn:cts:latinLit:phi1221.phi007.perseus-lat1:0-5"],
            "query"=>"s=2",
            "dc:format"=>"http://data.perseus.org/rdfvocab/treebank"},
           {"about"=>["urn:cts:latinLit:phi1221.phi007.perseus-lat1:0-5"],
            "query"=>"s=3",
            "dc:format"=>"http://data.perseus.org/rdfvocab/treebank"},
           {"about"=>["urn:cts:latinLit:phi1221.phi007.perseus-lat1:0-5"],
            "query"=>"s=4",
            "dc:format"=>"http://data.perseus.org/rdfvocab/treebank"}]
         }
         assert_equal(expected, test.as_ro())
       end
     end  

  end
end
