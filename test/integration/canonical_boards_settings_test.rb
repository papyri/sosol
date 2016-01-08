require 'test_helper'

class CanonicalBoarsSettingsTest < ActionController::IntegrationTest
  setup do

    Rails.logger.level = 0
    # Do setup allowing canonical boards to enable creation of migration scenario
    Sosol::Application.config.allow_canonical_boards = true
    Sosol::Application.config.submit_canonical_boards = true

    # master community for the board
    @community = FactoryGirl.create(:master_community, :is_default => false, :allows_self_signup => true )
    #a user to put on the boards
    @board_user = FactoryGirl.create(:user, :name => "board_man_bob")
    @board_user_2 = FactoryGirl.create(:user, :name => "board_man_alice")
    #a user to submit publications
    @creator_user = FactoryGirl.create(:user, :name => "creator_bob")

    #set up the boards, and vote
    @meta_board = FactoryGirl.create(:hgv_meta_board, :title => "meta")
    @meta_community_board = FactoryGirl.create(:hgv_meta_community_board, :title => "meta", :community => @community)


    #the board memeber
    @meta_board.users << @board_user

    #the vote
    @meta_decree = FactoryGirl.create(:count_decree,
                                      :board => @meta_board,
                                      :trigger => 1.0,
                                      :action => "approve",
                                      :choices => "ok")
    @meta_board.decrees << @meta_decree

    #set board order
    @meta_board.rank = 1

    # create a canonical publication
    @publication = Publication.new_from_templates(@creator_user)
  end

  teardown do
    Sosol::Application.config.allow_canonical_boards = true
    Sosol::Application.config.submit_canonical_boards = true
    begin
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        count = 0
        [ @board_user, @board_user_2, @creator_user, @meta_board, @meta_community_board, @community ].each do |entity|
          count = count + 1
          unless entity.nil?
            entity.reload
            entity.destroy
          end
        end
      end
    end
  end

  context "with allow_canonical_boards true, submit_canonical_board false" do
    setup do
      Sosol::Application.config.submit_canonical_boards = false
    end

    should "not show canonical boards in submit menu"  do

      Rails.logger.debug "---Testing Submittable Communities---"
      assert_not_nil @publication
      get 'publications/' + @publication.id.to_s + '?test_user_id=' + @creator_user.id.to_s 
      assert assigns(:submittable_communities)
      assert_equal [@community.id], assigns(:submittable_communities).values
    end
  end

  context "with allow_canonical_boards false and submit_canonical_boards fase" do
    setup do
      Sosol::Application.config.allow_canonical_boards = false
      Sosol::Application.config.submit_canonical_boards = false
    end

    should "fail to submit a publication without a community"  do

      get 'publications/' + @publication.id.to_s + '?test_user_id=' + @creator_user.id.to_s 
      assert assigns(:submittable_communities)
      assert_equal [@community.id], assigns(:submittable_communities).values
      assert_raises(RuntimeError) {
        post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, :submit_comment => "I made a new pub"
      }
    end

    should "fail to finalize a publication without a community"  do
      Sosol::Application.config.allow_canonical_boards = true
      post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, :submit_comment => "I made a new pub"
      @publication.reload

      assert_nil @publication.community, "Community should be NIL"

      #now meta should have it
      assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

      #meta board should have 1 publication
      meta_publications = Publication.find(:all, :conditions => { :owner_id => @meta_board.id, :owner_type => "Board" } )
      assert_equal 1, meta_publications.length, "Meta does not have 1 publication but rather, " + meta_publications.length.to_s + " publications"


      #vote on it
      meta_publication = meta_publications.first

      assert !meta_publication.creator_commits.empty?, "submitted publication should have creator commits"

      #find meta identifier
      meta_identifier = nil
      meta_publication.identifiers.each do |id|
        if @meta_board.controls_identifier?(id)
          meta_identifier = id
        end
      end


      post 'publications/vote/' + meta_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
        :comment => { :comment => "I agree meta is great", :user_id => @board_user.id, :publication_id => meta_identifier.publication.id, :identifier_id => meta_identifier.id, :reason => "vote" }, \
        :vote => { :publication_id => meta_identifier.publication.id.to_s, :identifier_id => meta_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @meta_board.id.to_s, :choice => "ok" }

      #reload the publication to get the vote associations to go thru?
      meta_publication.reload

      assert_equal 1, meta_publication.votes.length, "Meta publication should have one vote"
      assert_equal 1, meta_publication.children.length, "Meta publication should have one child"

      #vote should have changed publication to approved and put to finalizer
      assert_equal "approved", meta_publication.status, "Meta publication not approved after vote"

      meta_final_publication = meta_publication.find_finalizer_publication
      assert_equal meta_final_publication.status, "finalizing", "Board user's publication is not for finalizing"

      #call finalize on publication controller

      meta_final_identifier = nil
      meta_final_publication.identifiers.each do |id|
        if @meta_board.controls_identifier?(id)
          meta_final_identifier = id
        end
      end

      assert meta_final_identifier.content, "finalizing publication's identifier should have content"

      assert ! @publication.needs_rename?
      put 'publications/' + meta_final_publication.id.to_s + '/hgv_meta_identifiers/' + meta_final_identifier.id.to_s + '/rename/?test_user_id='  + @board_user.id.to_s, :new_name => 'papyri.info/hgv/00000000xx'
      # now turn off canonical boards and confirm finalization raises error
      Sosol::Application.config.allow_canonical_boards = false
      assert_raises(RuntimeError) {
        post 'publications/' + meta_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
          :comment => 'I agree meta is great and now it is final'
      }
    end
  end
end
