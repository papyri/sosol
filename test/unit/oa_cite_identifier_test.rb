require 'test_helper'

class OaCiteIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = Factory(:user, :name => "Creator")
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

    should "work with gss key pub url" do
      init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
      test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      assert_not_nil test
    end

    should "work with gss key link url" do
      init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
      test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      assert_not_nil test
    end

    should "work with gss pub url" do
      init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
      test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      assert_not_nil test
    end

    should "work with gss link url" do
      init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/edit?usp=sharing"]
      test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
      assert_not_nil test
    end

    should "raise error" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc"]
        exception = assert_raises(RuntimeError) {
          test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        }
        assert_match(/^Invalid URL/,exception.message)
    end

  end
   
   # TODO new version from existing version - same annotator 
   # TODO new version from existing version - new annotator (adds annotator)
   # TODO rename updates uri

end
