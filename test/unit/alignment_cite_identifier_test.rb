require 'test_helper'

class AlignmentCiteIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = Factory(:user, :name => "Creator2")
      @publication = Factory(:publication, :owner => @creator, :creator => @creator, :status => "new")

      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
      @tokenized_lat = File.read(File.join(File.dirname(__FILE__), 'responses', 'tokenized_lat.xml'))
    end
    
    teardown do
      unless @publication.nil?
        @publication.destroy
      end
      unless @creator.nil?
        #@creator.destroy
      end
    end
       
    should "create template dummy non-cts" do      
      AlignmentCiteIdentifier::XML_TOKENIZER = stub("my tokenizer")
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_tokenized_passage).returns(@tokenized_lat)
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_subref).returns('Troiae[1]-venit[1]')
      test = AlignmentCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://test1.org","http://test2.org"])
      assert_not_nil test
      # ideally we should do an XML comparison
      template = REXML::Document.new(test.content).root
      # make sure things got set from the transformed tokenized passage
      assert_equal 'lat', REXML::XPath.first(template,"//align:language[@lnum='L1']",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).attributes['xml:lang']
      assert_equal 'lat', REXML::XPath.first(template,"//align:language[@lnum='L2']",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).attributes['xml:lang']
      assert_equal 'ltr', REXML::XPath.first(template,"//align:language[@lnum='L1']",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).attributes['dir']
      assert_equal 'ltr', REXML::XPath.first(template,"//align:language[@lnum='L2']",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).attributes['dir']
      assert_equal 'cite/perseus/testcoll.1.1', REXML::XPath.first(template,"//align:sentence",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).attributes['document_id']
      assert_equal 12, REXML::XPath.match(template,"//align:sentence/align:wds[@lnum='L1']/align:w",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).length
      assert_equal 12, REXML::XPath.match(template,"//align:sentence/align:wds[@lnum='L2']/align:w",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).length
      assert_equal 'http://test1.org', REXML::XPath.first(template,"//align:sentence/align:wds[@lnum='L1']/align:comment[@class='uri']",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).text
      assert_equal 'http://test2.org', REXML::XPath.first(template,"//align:sentence/align:wds[@lnum='L2']/align:comment[@class='uri']",{"align" => AlignmentCiteIdentifier::NS_ALIGN}).text
      assert_equal "Alignment of http://test1.org and http://test2.org", test.title
    end
    
    should "see as match" do
      AlignmentCiteIdentifier::XML_TOKENIZER = stub("my tokenizer")
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_tokenized_passage).returns(@tokenized_lat)
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_subref).returns('Troiae[1]-venit[1]')
      test = AlignmentCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://test1.org","http://test2.org"])
      assert test.is_match?(["http://test1.org","http://test2.org"])

    end
    
    should "not see as match" do
      AlignmentCiteIdentifier::XML_TOKENIZER = stub("my tokenizer")
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_tokenized_passage).returns(@tokenized_lat)
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_subref).returns('Troiae[1]-venit[1]')
      test = AlignmentCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://test1.org","http://test2.org"])
      assert ! test.is_match?(["http://test1.org","http://test3.org"])

    end

    should "strip uri from title" do
      AlignmentCiteIdentifier::XML_TOKENIZER = stub("my tokenizer")
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_tokenized_passage).returns(@tokenized_lat)
      AlignmentCiteIdentifier::XML_TOKENIZER.stubs(:get_subref).returns('Troiae[1]-venit[1]')
      test = AlignmentCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll",["http://test1.org/urn:cts:xxx","http://test2.org/urn:cts:yyy"])
      assert_equal "Alignment of urn:cts:xxx and urn:cts:yyy", test.title

    end
    
   end  
   

end