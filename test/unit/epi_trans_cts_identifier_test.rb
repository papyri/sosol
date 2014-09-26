require 'test_helper'

class EpiTransCTSIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = Factory(:user, :name => "Creator1")
      @publication = Factory(:publication, :owner => @creator, :creator => @creator, :status => "new")

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
       
    should "create from template" do      
      test = EpiTransCTSIdentifier.new_from_template(@publication,"testepi","urn:cts:test:tg1.wk1",'translation','fre')
      assert_not_nil test.xml_content
      assert_equal("fre",test.lang)
    end

    should "set correct identifier for work" do
      urn = "urn:cts:pdlepi:eagle.tm179252"
      next_temp = CTSIdentifier.next_temporary_identifier("pdlepi",urn,"translation","fr")
      assert_equal("pdlepi/pdlepi/eagle.tm179252/translation/TempTexts-fr-2014-1", next_temp) 
    end

    should "set correct identifier ignoring version" do
      urn = "urn:cts:pdlepi:eagle.tm179252.perseids-fr-1"
      next_temp = CTSIdentifier.next_temporary_identifier("pdlepi",urn,"translation","fr")
      assert_equal("pdlepi/pdlepi/eagle.tm179252/translation/TempTexts-fr-2014-1", next_temp) 
    end


    should "not duplicate identifiers" do
      test = EpiTransCTSIdentifier.new_from_template(@publication,"testepi","urn:cts:test:tg1.wk1",'translation','fre')
      assert_equal("testepi/test/tg1.wk1/translation/perseids-fre-2014-1", test.name)
      test2 = EpiTransCTSIdentifier.new_from_template(@publication,"testepi","urn:cts:test:tg1.wk1",'translation','fre')
      assert_equal("testepi/test/tg1.wk1/translation/perseids-fre-2014-2", test2.name)
    end
    
   end  
   
end
