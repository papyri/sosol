require 'test_helper'

class TreebankCiteIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = FactoryGirl.create(:user, :name => "Creator2")
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
    
    end
    
    teardown do
      unless @publication.nil?
        @publication.destroy
      end
      unless @creator.nil?
        #@creator.destroy
      end
    end
       
    should "create from template in repo" do      
      target_cite_urn =  CTS::CTSLib.urnObj("urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4")
      test_path = "CITE_TREEBANK_XML/template/data.perseus.org/citations/latinLit/phi0631/phi002/phi0631.phi002.perseus-lat1.1-4.tb.xml"
      test = TreebankCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:lattb","http://data.perseus.org/citations/urn:cts:latinLit:phi0631.phi002.perseus-lat1:1-4") 
      template_path = test.path_for_target("template","http://data.perseus.org/citations/",target_cite_urn)
      assert_equal template_path, test_path
      assert_not_nil test.xml_content
      assert test.is_valid_xml?(test.xml_content)
      template_xml = REXML::Document.new(test.xml_content)
      assert_not_nil REXML::XPath.first(template_xml,"/treebank")
      assert_not_nil REXML::XPath.first(template_xml,"/treebank/annotator")
      assert_equal REXML::XPath.first(template_xml,"/treebank/annotator/uri").text, "http://data.perseus.org/users/Creator2"
      assert_not_nil REXML::XPath.first(template_xml,"/treebank/date")
      

    end
    
   end  
   

end
