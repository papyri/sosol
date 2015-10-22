require 'test_helper'
require 'ddiff'

#require File.dirname(__FILE__) + '/session_set_controller'

=begin
This file tests the End User Community workflow.

The End User Community workflow is similar to a Master Community workflow (or the default SoSOL 
workflow) except that the publication/identifiers are not committed to the canon on finalize. 
Instead the changes made by the finalizer are copied back to the submitters origin publication.
Once the publication has been vetted by all the community boards, the "committed" version 
is copied to the communities end_user. The end_user's copy is severed from any connections 
to the origin publication (all changes are still held in the git history) and appears in the 
end_user's dashboard as an editing publication. Social convention should be that the end user 
is only used for collecting the communities approved publications. That way when the publications
are submitted to the sosol boards, they will be marked as coming from the end_user associated 
with the community.  

This test creates a new publication and immediately submits it to a community.
Each community board recieves the submit, votes on it, then sends it to the finalizer.
The finalizer finalizes it, which copies the changes back to the original submitter.
=end

class EndUserCommunityWorkflowTest < ActionController::IntegrationTest
  def compare_publications(a,b)

    pubs_are_matched = true
    a.identifiers.each do |aid|
      id_has_match = false
      b.identifiers.each do |bid|
        if (aid.class.to_s == bid.class.to_s && aid.title == bid.title)
          if (aid.xml_content == bid.xml_content)
            id_has_match = true
            Rails.logger.debug "Identifier match found"
          else
            if aid.xml_content == nil
              Rails.logger.debug a.title + " has nill " + aid.class.to_s + " identifier"
            end
            if bid.xml_content == nil
              Rails.logger.debug b.title + " has nill " + bid.class.to_s + " identifier"
            end
            Rails.logger.debug "Identifier diffs for " + a.title + " " + b.title + " " + aid.class.to_s + " " +  aid.title
            log_diffs(aid.xml_content.to_s, bid.xml_content.to_s )
            #Rails.logger.debug "full xml a " + aid.xml_content
            #Rails.logger.debug "full xml b " + bid.xml_content
          end
        end
      end

      if !id_has_match
        pubs_are_matched = false
        Rails.logger.debug "--Mis matched publication. Id " + aid.title + " " + aid.class.to_s + " are different"
      end
    end

    if pubs_are_matched
      Rails.logger.debug "Publications are matched"
    end

  end

  def log_diffs(a, b)
    a_to_b_diff = a.diff(b)

    plus_str = ""
    minus_str = ""
    a_to_b_diff.diffs.each do |d|
      d.each do |mod|
        if mod[0] == "+"
          plus_str = plus_str + mod[2].chr
        else
          minus_str = minus_str + mod[2].chr
        end
      end
    end

    Rails.logger.debug "added " + plus_str
    Rails.logger.debug "removed " + minus_str

  end

  def output_publication_info(publication)
    Rails.logger.info "-----Publication Info-----"
    Rails.logger.info "--Owner: " + publication.owner.name
    Rails.logger.info "--Title: " + publication.title
    Rails.logger.info "--Status: " + publication.status
    Rails.logger.info "--content"

    publication.identifiers.each do |id|
      Rails.logger.info "---ID title: " + id.title
      Rails.logger.info "---ID class:" + id.class.to_s
      Rails.logger.info "---ID content:"
      if id.xml_content
        Rails.logger.info id.xml_content
      else
        Rails.logger.info "NO CONTENT!"
      end
      #Rails.logger.info "== end Owner: " + publication.owner.name
    end
    Rails.logger.info "==end Owner: " + publication.owner.name
    Rails.logger.info "=====End Publication Info====="
  end
end

class EndUserCommunityWorkflowTest < ActionController::IntegrationTest
  context "for community" do
    context "community testing" do
      setup do
        #Rails.logger.level = :debug
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx community testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        Rails.logger.debug "*************are we in debug mode***************"

        #a user to put on the boards
        @board_user = FactoryGirl.create(:user, :name => "board_man_freaky_bob")
        @board_user_2 = FactoryGirl.create(:user, :name => "board_man_freaky_alice")
        #a user to submit publications
        @creator_user = FactoryGirl.create(:user, :name => "creator_freaky_bob")
        #an end user to recieve the "finalized" publication
        @end_user = FactoryGirl.create(:user, :name => "end_freaky_bob")

        #a general member in the community
        @community_user = FactoryGirl.create(:user, :name => "community_freaky_bob")

        #a user to make a publication so we are not testing SOSOL 2011 1 (local bug-this one somehow got added to canonical)
        @trash_user = FactoryGirl.create(:user, :name => "just_to_make_another_publication")

        #set up the community
        @test_community = FactoryGirl.create(:end_user_community,
                                             :name => "test_freaky_community",
                                             :friendly_name => "testy",
                                             :allows_self_signup => true,
                                             #:abbreviation => "tc",
                                             :description => "a comunity for testing")

        @test_community.members << @community_user
        @test_community.end_user_id = @end_user.id
        @test_community.save

        #set up the boards, and vote
        #@meta_board = FactoryGirl.create(:community_meta_board, :title => "meta", :community_id => @test_community.id)
        @meta_board = FactoryGirl.create(:hgv_meta_board, :title => "meta", :community_id => @test_community.id)

        #the board member
        @meta_board.users << @board_user
        #@meta_board.users << @board_user_2

        #the vote
        @meta_decree = FactoryGirl.create(:count_decree,
                                          :board => @meta_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")

        @meta_board.decrees << @meta_decree

        #add board to community
        @test_community.boards << @meta_board



        #@text_board = FactoryGirl.create(:community_text_board, :title => "text", :community_id => @test_community.id)
        @text_board = FactoryGirl.create(:board, :title => "text", :community_id => @test_community.id)
        #the board memeber
        @text_board.users << @board_user
        #the vote
        @text_decree = FactoryGirl.create(:count_decree,
                                          :board => @text_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")

        @text_board.decrees << @text_decree
        #add board to community
        @test_community.boards << @text_board

        #@translation_board = FactoryGirl.create(:community_translation_board, :title => "translation", :community_id => @test_community.id)
        @translation_board = FactoryGirl.create(:hgv_trans_board, :title => "translation", :community_id => @test_community.id)

        #the board memeber
        @translation_board.users << @board_user
        #the vote
        @translation_decree = FactoryGirl.create(:count_decree,
                                                 :board => @translation_board,
                                                 :trigger => 1.0,
                                                 :action => "approve",
                                                 :choices => "ok")

        @translation_board.decrees << @translation_decree

        #add board to community
        @test_community.boards << @translation_board

        #set board order
        @meta_board.rank = 1
        @text_board.rank = 2
        @translation_board.rank = 3

        Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz community testing setup complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
      end

      teardown do
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx community testing teardown begin xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        begin
          ActiveRecord::Base.connection_pool.with_connection do |conn|
            count = 0
            [ @board_user, @board_user_2, @creator_user, @end_user, @community_user, @trash_user, @test_community ].each do |entity|
              count = count + 1
              #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil."
              unless entity.nil?
                entity.reload
                entity.destroy
              end
            end
          end
        end
        Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz community testing teardown complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
      end

      should "user creates and submits publication to community"  do
        Rails.logger.debug "BEGIN TEST: user creates and submits publication to community"

        Rails.logger.debug "---Meta board controlls: "
        @meta_board.identifier_classes.each do |mic|
          Rails.logger.debug mic
        end

        assert_not_equal nil, @test_community, "Community not created"

        assert_not_nil @trash_user, "No Trash user created"
        #for testing create a publication so the next one will be another number create a publication with a session
        open_session do |trash_publication_session|
          Rails.logger.debug "---Create A New Trash Publication---"
          trash_publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @trash_user.id.to_s
          Rails.logger.debug "--flash is: " + trash_publication_session.flash.inspect
          @trash_publication = @trash_user.publications.first
          @trash_publication.log_info
        end

        #create a publication with a session
        open_session do |publication_session|
          Rails.logger.debug "---Create A New Publication---"
          publication_session.post 'publications/create_from_templates' + '?test_user_id=' + @creator_user.id.to_s
          Rails.logger.debug "--flash is: " + publication_session.flash.inspect
          @publication = @creator_user.publications.first
          @publication.log_info
        end

        Rails.logger.debug "---Publication Created---"
        Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

        @publication.identifiers.each do |pi|
          Rails.logger.debug "-identifier-"
          Rails.logger.debug "title is: " +  pi.title
          Rails.logger.debug "was it modified?: " + pi.modified?.to_s
          # Rails.logger.debug "xml:"
          # Rails.logger.debug pi.xml_content
        end

        #submit to the community
        Rails.logger.debug "---Submit Publication---"
        open_session do |submit_session|
          submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, \
            :submit_comment => "I made a new pub", :community => { :id => @test_community.id.to_s }
          assert_equal "Publication submitted to #{@test_community.friendly_name}.", submit_session.flash[:notice]
          Rails.logger.debug "--flash is: " + submit_session.flash.inspect
        end
        @publication.reload

        #now meta should have it
        assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

        Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name

        #meta board should have 1 publication, others should have 0
        meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
        assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"

        text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
        assert_equal 0, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

        translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
        assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

        Rails.logger.debug "Community Meta Board has publication"

        #vote on it
        meta_publication = meta_publications.first

        #find meta identifier
        meta_identifier = nil
        meta_publication.identifiers.each do |id|
          if @meta_board.controls_identifier?(id)
            meta_identifier = id
          end
        end

        assert_not_nil  meta_identifier, "Did not find the meta identifier"
        Rails.logger.debug "Found meta identifier, will vote on it"

        #vote on meta publication
        open_session do |meta_session|
          meta_session.post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
            :comment => { :comment => "I vote to agree meta is great", :user_id => @board_user.id, :publication_id => meta_identifier.publication.id, :identifier_id => meta_identifier.id, :reason => "vote" }, \
            :vote => { :publication_id => meta_identifier.publication.id.to_s, :identifier_id => meta_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @meta_board.id.to_s, :choice => "ok" }

          Rails.logger.debug "--flash is: " + meta_session.flash.inspect
          
        end
        
        #reload the publication to get the vote associations to go thru?
        meta_publication.reload

        vote_str = "Votes on meta are: "
        meta_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        Rails.logger.debug  vote_str

        assert_equal 1, meta_publication.votes.length, "Meta publication should have one vote"
        assert_equal 1, meta_publication.children.length, "Meta publication should have one child"

        #vote should have changed publication to approved and put to finalizer
        assert_equal "approved", meta_publication.status, "Meta publication not approved after vote"
        Rails.logger.debug "--Meta publication approved"

        #now finalizer should have it
        meta_final_publication = meta_publication.find_finalizer_publication

        assert_equal meta_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
        Rails.logger.debug "---Meta Finalizer has publication"

        meta_final_identifier = nil
        meta_final_publication.identifiers.each do |id|
          if @meta_board.controls_identifier?(id)
            meta_final_identifier = id
          end
        end

        # do rename
        open_session do |meta_rename_session|
          meta_rename_session.put 'publications/' + meta_final_publication.id.to_s + '/hgv_meta_identifiers/' + meta_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s,
            :new_name => 'papyri.info/hgv/9999999999'
        end

        meta_final_publication.reload
        assert !meta_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

        #finalize the meta
        open_session do |meta_finalize_session|

          meta_finalize_session.post 'publications/' + meta_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
            :comment => 'I agree meta is great and now it is final'

          Rails.logger.debug "--flash is: " + meta_finalize_session.flash.inspect
          Rails.logger.debug "----session data is: " + meta_finalize_session.session.to_hash.inspect
          Rails.logger.debug meta_finalize_session.body
        end

        meta_final_publication.reload
        assert_equal "finalized", meta_final_publication.status, "Meta final publication not finalized"

        Rails.logger.debug "Meta committed"

        #compare the publications
        #you must look at the output to check the results of the comparisons
        #final and submitters' copy should have comments and votes
        Rails.logger.debug "++++++++USER PUBLICATION++++++"
        @creator_user.publications.first.log_info

        meta_publication.reload
        Rails.logger.debug "++++++++meta BOARD PUBLICATION++++++"
        meta_publication.log_info

        meta_final_publication.reload
        Rails.logger.debug "++++++++meta FINAL PUBLICATION++++++"
        meta_final_publication.log_info

        Rails.logger.debug "Compare board with board publication"
        compare_publications(meta_publication, meta_publication)
        Rails.logger.debug "Compare board with finalizer publication"
        compare_publications(meta_publication, meta_final_publication)

        Rails.logger.debug "Compare user with meta finalizer publication"
        compare_publications(@creator_user.publications.first, meta_final_publication)

        end_publication = @end_user.publications.first
        assert_nil end_publication, "--Community end user has a publication before they should (after meta has been finalized)"
        #meta testing complete

        #=================================TEXT BOARD==========================================
        #now text board should have it

        #meta board should have 1 publication
        meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
        assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"

        #text board should have 1 publication
        text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
        assert_equal 1, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

        #translation board should have 0 publication
        translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
        assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

        #vote on it
        text_publication = text_publications.first

        #find text identifier
        text_identifier = nil
        text_publication.identifiers.each do |id|
          if @text_board.controls_identifier?(id)
            text_identifier = id
          end
        end

        assert_not_nil  text_identifier, "Did not find the text identifier"

        Rails.logger.debug "Found text identifier, will vote on it"
        #vote on text
        open_session do |text_session|
          text_session.post 'publications/vote/' + text_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
            :comment => { :comment => "I vote since I yippppppp agree text is great", :user_id => @board_user.id, :publication_id => text_identifier.publication.id, :identifier_id => text_identifier.id, :reason => "vote" }, \
            :vote => { :publication_id => text_identifier.publication.id.to_s, :identifier_id => text_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @text_board.id.to_s, :choice => "ok" }
          Rails.logger.debug "--flash is: " + text_session.flash.inspect
        end

        #reload the publication to get the vote associations to go thru?
        text_publication.reload

        vote_str = "Votes on text are: "
        text_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        Rails.logger.debug  vote_str

        assert_equal 1, text_publication.votes.length, "Text publication should have one vote"
        Rails.logger.debug "After text publication voting, origin has children:"
        Rails.logger.debug text_publication.origin.children.inspect
        assert_equal 1, text_publication.children.length, "Text publication should have one child"

        #vote should have changed publication to approved and put to finalizer
        assert_equal "approved", text_publication.status, "Text publication not approved after vote"
        Rails.logger.debug "--Text publication approved"

        #now finalizer should have it, only one person on board so it should be them
        finalizer_publications = @board_user.publications
        assert_equal 2, finalizer_publications.length, "Finalizer does not have a new (text) publication to finalize"

        text_final_publication = text_publication.find_finalizer_publication
        assert_not_nil text_final_publication, "Publicaiton does not have text finalizer"
        Rails.logger.debug "---Finalizer has text publication"

        text_final_identifier = nil
        text_final_publication.identifiers.each do |id|
          if @text_board.controls_identifier?(id)
            text_final_identifier = id
          end
        end

        # do rename
        open_session do |text_rename_session|
          text_rename_session.put 'publications/' + text_final_publication.id.to_s + '/ddb_identifiers/' + text_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s,
            :new_name => 'papyri.info/ddbdp/bgu;1;999', :set_dummy_header => false
        end

        text_final_publication.reload
        assert !text_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

        #finalize text
        open_session do |text_finalize_session|
          text_finalize_session.post 'publications/' + text_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
            :comment => 'I agree text is great and now it is final'

          Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
          Rails.logger.debug "----session data from text finalize is:" + text_finalize_session.session.to_hash.inspect
          Rails.logger.debug text_finalize_session.body
          Rails.logger.debug "--flash is: " + text_finalize_session.flash.inspect
        end

        text_final_publication.reload
        assert_equal "finalized", meta_final_publication.status, "Text final publication not finalized"

        #text finalized
        Rails.logger.debug "---Text publication Finalized"

        #output results for visual inspection
        current_creator_publication = @creator_user.publications.first
        current_creator_publication.reload

        current_creator_publication.log_info

        meta_final_publication.reload
        meta_final_publication.log_info

        #text_final_publication.reload
        text_final_publication.log_info

        Rails.logger.debug "Compare user with text finalizer publication"
        compare_publications(@creator_user.publications.first, text_final_publication)

        #check that end user now has the publication
        end_publication = @end_user.publications.first
        assert_not_nil end_publication, "--Community end user has no publications"

        compare_publications(@creator_user.publications.first, @end_user.publications.first)
        @publication.destroy

        Rails.logger.debug "ENDED TEST: user creates and submits publication to community"
      end
    end
  end
end
