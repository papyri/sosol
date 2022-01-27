# frozen_string_literal: true

require 'test_helper'

class DDBIdentifierTest < ActiveSupport::TestCase
  context 'collection names' do
    setup do
      @collection_names = DDBIdentifier.collection_names
    end

    should 'be unique' do
      assert_equal @collection_names.uniq, @collection_names
    end
  end

  context 'identifier renaming' do
    setup do
      @creator = FactoryBot.create(:user, name: 'Creator')
      @publication = FactoryBot.create(:publication, owner: @creator, creator: @creator, status: 'new')
      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master

      @ddb_identifier = DDBIdentifier.new_from_template(@publication)
      @original_name = @ddb_identifier.name
      @original_content = @ddb_identifier.content
      @original_path = @ddb_identifier.to_path
    end

    teardown do
      @publication.destroy
      @creator.destroy
    end

    should 'raise an error when the destination exists' do
      assert_raise RuntimeError do
        @ddb_identifier.rename('papyri.info/ddbdp/bgu;1;1')
      end
    end

    context 'with a valid target' do
      setup do
        @new_name = 'papyri.info/ddbdp/bgu;1;1000'
        @ddb_identifier.rename(@new_name)
      end

      should 'have the new name' do
        assert_equal @new_name, @ddb_identifier.name
      end

      should 'have the correct new title' do
        expected_title = FactoryBot.build(:DDBIdentifier, name: @new_name).titleize
        assert_equal expected_title, @ddb_identifier.title
      end

      should 'have the correct content at the new path' do
        assert_equal @original_content, @ddb_identifier.content
      end

      should 'have nothing at the original path' do
        assert_nil @creator.repository.get_file_from_branch(@original_path, @publication.branch)
      end
    end
  end

  context 'identifier mapping' do
    setup do
      @path_prefix = DDBIdentifier::PATH_PREFIX
    end

    # TODO: write a DDBIdentifier method for reversing a collection name
    # into a series number and use that here instead?
    # (e.g. #{DDBIdentifier.collection_to_series('bgu')} instead of 0001)

    should 'map the first identifier' do
      bgu_1_1 = FactoryBot.build(:DDBIdentifier, name: 'papyri.info/ddbdp/bgu;1;1')
      assert_path_equal %w[bgu bgu.1 bgu.1.1.xml], bgu_1_1.to_path
    end

    should 'map ambiguous collections' do
      bgu_ppetr_2_1 = FactoryBot.build(:DDBIdentifier, name: 'papyri.info/ddbdp/p.petr;2;1')
      assert_path_equal %w[p.petr p.petr.2 p.petr.2.1.xml], bgu_ppetr_2_1.to_path

      bgu_ppetr2_1 = FactoryBot.build(:DDBIdentifier, name: 'papyri.info/ddbdp/p.petr.2;;1')
      assert_path_equal %w[p.petr.2 p.petr.2.1.xml], bgu_ppetr2_1.to_path
    end

    # TODO: update this test for + solution
    # should "map files with '+' in the identifier" do
    #   chla_5_299FrA_B_C = FactoryBot.build(:DDBIdentifier, :name => "papyri.info/ddbdp/0279:5:299FrA+B+C")
    #   assert_path_equal %w{chla chla.5 chla.5.299FrA+B+C.xml}, chla_5_299FrA_B_C.to_path
    # end

    should "map files with ',' in the identifier" do
      bgu_13_2230_1 = FactoryBot.build(:DDBIdentifier, name: 'papyri.info/ddbdp/bgu;13;2230,1')
      assert_path_equal %w[bgu bgu.13 bgu.13.2230-1.xml], bgu_13_2230_1.to_path
    end

    should "map files with '/' in the identifier" do
      o_bodl_2_1964_1967 = FactoryBot.build(:DDBIdentifier, name: 'papyri.info/ddbdp/o.bodl;2;1964/1967')
      assert_path_equal %w[o.bodl o.bodl.2 o.bodl.2.1964_1967.xml], o_bodl_2_1964_1967.to_path
    end

    # Irrelevant now?
    # should "raise an error if series is non-existent" do
    #   no_series = FactoryBot.build(:DDBIdentifier, :name => "papyri.info/ddbdp/;1;1")
    #   assert_raise RuntimeError do
    #     no_series.to_path
    #   end
    #
    #   nonsense_series = FactoryBot.build(:DDBIdentifier, :name => "papyri.info/ddbdp/3735928559:1:1")
    #   assert_raise RuntimeError do
    #     nonsense_series.to_path
    #   end
    # end

    # TODO: populate this test
    should 'raise an error for illegal characters' do
      assert true
    end

    # NOTE: this is an extremely slow exhaustive test you should probably
    # only run to discover additional tests that need to be written.
    # As of 8/20/09, this will fail for every file in p.vind.eirene.
    # See: http://idp.atlantides.org/trac/idp/ticket/82
    # should "map every identifier found in a canonical DDB file back to the same file" do
    #       canonical = Repository.new
    #       files = canonical.get_all_files_from_path_on_branch(@path_prefix)
    #       files.each do |filename|
    #         Rails.logger.info "Filename: #{filename}"
    #         # reusing the same Repository instance here leads to an eventual
    #         # Grit timeout; possible Grit bug/leak?
    #         xml_content = REXML::Document.new(Repository.new.get_file_from_branch(filename))
    #         ddb_hybrid = REXML::XPath.first(xml_content, '/TEI//idno[@type = "ddb-hybrid"]').text
    #         Rails.logger.info "DDB Hybrid: #{ddb_hybrid}"
    #         identifier_name = "papyri.info/ddbdp/#{ddb_hybrid}"
    #         Rails.logger.info "Identifier to hash: #{NumbersRDF::NumbersHelper.identifiers_to_hash(NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier_name)).inspect}"
    #         this_ddb = FactoryBot.build(:DDBIdentifier, :name => identifier_name)
    #         assert_equal filename, this_ddb.to_path
    #       end
    #     end
  end
end
