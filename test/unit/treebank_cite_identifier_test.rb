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
         
      should "create from template in repo" do      
        test_path = "CITE_TREEBANK_XML/template/data.perseus.org/citations/latinLit/phi0631/phi002/phi0631.phi002.perseus-lat1.1-4.tb.xml"
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert_not_nil test.xml_content
        assert test.is_valid_xml?(test.xml_content)
        template_xml = REXML::Document.new(test.xml_content)
        assert_not_nil REXML::XPath.first(template_xml,"/treebank")
        assert_not_nil REXML::XPath.first(template_xml,"/treebank/annotator")
        assert_equal REXML::XPath.first(template_xml,"/treebank/annotator/uri").text.strip, "#{Sosol::Application.config.site_user_namespace}Creator"
        assert_not_nil REXML::XPath.first(template_xml,"/treebank/date")
        

      end

# commenting out until I have time to implement remote request as a mock      
#      should "create from url" do      
#        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://cdn.rawgit.com/PerseusDL/treebank_data/master/v1.6/latin/data/phi0690.phi003.perseus-lat1.tb.xml"])
#        assert_not_nil test.xml_content
#        # make sure we actually retrieved something -- the bare template doesn't have word forms
#        template_xml = REXML::Document.new(test.xml_content)
#        assert_not_equal("",REXML::XPath.first(template_xml,"/treebank/sentence/word").attributes["form"])
#        assert_equal("CITE_TREEBANK_XML/perseus/testcoll/1/testcoll.1.1.tb.xml",test.to_path())
#      end
      
      should "fail from url" do      
        exception = assert_raises(RuntimeError) {
          test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://www.perseus.tufts.edu/hopper/xmlchunk?doc=Perseus%3Atext%3A1999.02.0003%3Apoem%3D1"])
        }
        assert_equal("Invalid treebank content at http://www.perseus.tufts.edu/hopper/xmlchunk?doc=Perseus%3Atext%3A1999.02.0003%3Apoem%3D1",exception.message)
      end

      should "match_on_urn" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert test.is_match? ["urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]
      end

      should "match_on_urn_other_provider" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert test.is_match? ["http://other.org/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]
      end

      should "match_on_urn_part" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert test.is_match? ["urn:cts:latinLit:phi0631.phi002.perseus-lat1:1"]
        assert test.is_match? ["urn:cts:latinLit:phi0631.phi002.perseus-lat1:4"]
        assert test.is_match? ["urn:cts:latinLit:phi0631.phi002.perseus-lat1"]
        assert test.is_match? ["urn:cts:latinLit:phi0631.phi002.perseus-lat1"]
        assert test.is_match? ["urn:cts:latinLit:phi0631.phi002.perseus-lat1:2"]
      end

      should "fail_match_on_urn" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert ! (test.is_match?(["urn:cts:latinLit:phi0632.phi002.perseus-lat1:1-4"]))
      end

      should "match_on_work_and_passage" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert test.is_match?(["urn:cts:latinLit:phi0631.phi002:1-4"])
      end

      should "match_on_work" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert test.is_match?(["urn:cts:latinLit:phi0631.phi002"])
      end

      should "not_match_on_partial_work" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert !(test.is_match?(["urn:cts:latinLit:phi0631.phi00"]))
      end

      should "match_on_textgroup" do
        test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4"]) 
        assert test.is_match?(["urn:cts:latinLit:phi0631"])
      end

      should "match_on_url" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'bobstb1.xml'))
        test = TreebankCiteIdentifier.api_create(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["http://bobsfiles.com/1.xml"])
      end

      should "match_on_url_urn" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
        test = TreebankCiteIdentifier.api_create(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
      end

      should "match_on_url_urn_with_urn" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
        test = TreebankCiteIdentifier.api_create(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
      end

      should "match_on_url_urn_with_urn_no_range" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurlnorange.xml'))
        test = TreebankCiteIdentifier.api_create(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
        assert ! test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.2"])
      end

      # this test is failing - the cts lib is doing something weird with the xml
      # bit -- reenable test when we upgrade to CTS 5
      #should "not_match_on_url_urn_with_extension" do
      #  file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
      #  test = TreebankCiteIdentifier.api_create(@publication,"http://testapp",file,"apicreate")
      #  assert ! test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1.xml"])
      #end
       should "parse annotation targets" do
         file = File.read(File.join(File.dirname(__FILE__), 'data', 'bobstb1.xml'))
         test = TreebankCiteIdentifier.api_create(@publication,"http://testapp",file,"apicreate")
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
