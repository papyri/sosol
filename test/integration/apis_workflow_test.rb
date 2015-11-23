require 'test_helper'
require 'ddiff'

class ApisWorkflowTest < ActionController::IntegrationTest
  def generate_board_vote_for_decree(board, decree, identifier, user)
    FactoryGirl.create(:vote,
                       :publication_id => identifier.publication.id,
                       :identifier_id => identifier.id,
                       :user => user,
                       :choice => (decree.get_choice_array)[rand(
                         decree.get_choice_array.size)])
  end

  def generate_board_votes_for_action(board, action, identifier)
    decree = board.decrees.detect {|d| d.action == action}
    vote_count = 0
    if decree.tally_method == Decree::TALLY_METHODS[:percent]
      while (((vote_count.to_f / decree.board.users.length)*100) < decree.trigger) do
        generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
        vote_count += 1
      end
    elsif decree.tally_method == Decree::TALLY_METHODS[:count]
      while (vote_count.to_f < decree.trigger) do
        generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
        vote_count += 1
      end
    end
  end

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
        Rails.logger.debug "--Mis matched publication. Id " + aid.title + " " + aid.class.to_s + " is different"
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
end


class ApisWorkflowTest < ActionController::IntegrationTest
  context "for idp3" do
    context "apis testing" do
      setup do
        Rails.logger.level = 0
        Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx sosol testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        @community = FactoryGirl.create(:master_community, :is_default => true, :allows_self_signup => true )
        #a user to put on the boards
        @board_user = FactoryGirl.create(:user, :name => "board_man_bob")
        @board_user_2 = FactoryGirl.create(:user, :name => "board_man_alice")

        #a user to submit publications
        @creator_user = FactoryGirl.create(:user, :name => "creator_bob")

        #an end user to recieve the "finalized" publication
        @end_user = FactoryGirl.create(:user, :name => "end_bob")

        #set up the boards, and decrees
        @meta_board = FactoryGirl.create(:hgv_meta_board, :title => "meta", :community => @community)

        #the board memeber
        @meta_board.users << @board_user
        #@meta_board.users << @board_user_2

        #the decree
        @meta_decree = FactoryGirl.create(:count_decree,
                                          :board => @meta_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")
        @meta_board.decrees << @meta_decree

        @text_board = FactoryGirl.create(:board, :title => "text", :community => @community)
        #the board memeber
        @text_board.users << @board_user
        #the vote
        @text_decree = FactoryGirl.create(:count_decree,
                                          :board => @text_board,
                                          :trigger => 1.0,
                                          :action => "approve",
                                          :choices => "ok")
        @text_board.decrees << @text_decree

        @translation_board = FactoryGirl.create(:hgv_trans_board, :title => "translation", :community => @community)

        #the board memeber
        @translation_board.users << @board_user
        #the decree
        @translation_decree = FactoryGirl.create(:count_decree,
                                                 :board => @translation_board,
                                                 :trigger => 1.0,
                                                 :action => "approve",
                                                 :choices => "ok")
        @translation_board.decrees << @translation_decree

        @apis_board = FactoryGirl.create(:apis_board, :title => "nyu", :community => @community)
        @apis_board.users << @board_user

        #set board order
        @meta_board.rank = 1
        @text_board.rank = 2
        @translation_board.rank = 3
        @apis_board.rank = 4
        [@meta_board, @text_board, @translation_board, @apis_board].each do |board|
          board.save
        end
      end

      teardown do
        begin
          ActiveRecord::Base.connection_pool.with_connection do |conn|
            count = 0
            [ @board_user, @board_user_2, @creator_user, @end_user, @meta_board, @text_board, @translation_board, @community ].each do |entity|
              count = count + 1
              #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil."
              unless entity.nil?
                entity.reload
                entity.destroy
              end
            end
          end
        end
      end

      should "user creates and submits publication to sosol"  do
        Rails.logger.debug "BEGIN TEST: user creates and submits publication to sosol"

        assert_not_equal nil, @meta_board, "Meta board not created"
        assert_not_equal nil, @text_board, "Text board not created"
        assert_not_equal nil, @translation_board, "Translation board not created"

        #create a publication with a session
        open_session do |publication_session|
          #publication_session.data
          Rails.logger.debug "---Create A New Publication---"
          #publication_session.post 'publications/create_from_templates', :session => { :user_id => @creator_user.id }

          publication_session.post 'publications/create_from_identifier' + '?test_user_id=' + @creator_user.id.to_s, \
            :id => 'papyri.info/ddbdp/p.nyu;1;1'

          Rails.logger.debug "--flash is: " + publication_session.flash.inspect

          @publication = @creator_user.publications.first

          @publication.log_info
        end

        Rails.logger.debug "---APIS Publication Created---"
        Rails.logger.debug  "--identifier count is: " + @publication.identifiers.count.to_s

        an_array = @publication.identifiers
        Rails.logger.debug  "--identifier length via array is: " + an_array.length.to_s

        Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

        @publication.identifiers.each do |pi|
          Rails.logger.debug "-identifier-"
          Rails.logger.debug "title is: " +  pi.title
          Rails.logger.debug "was it modified?: " + pi.modified?.to_s
          Rails.logger.debug "xml:"
          Rails.logger.debug pi.xml_content
        end

        open_session do |edit_session|
          apis_identifier = @publication.identifiers.select {|i| i.class == APISIdentifier}.first
          assert !apis_identifier.modified?, "APIS Identifier should not be modified before we edit it"
          original_content = apis_identifier.xml_content
          modified_content = original_content.sub(/Bobst/, 'APIS Workflow Test')
          assert_not_equal original_content, modified_content, "Modified content should be modified"

          edit_session.put "publications/#{@publication.id.to_s}/apis_identifiers/#{apis_identifier.id.to_s}/?test_user_id=#{@creator_user.id.to_s}",
            :apis_identifier => {:xml_content => modified_content}, :comment => 'APIS Workflow Test'

          Rails.logger.debug "--APIS flash is: " + edit_session.flash.inspect

          apis_identifier.reload
          assert apis_identifier.modified?, "APIS Identifier should be modified after we edit it"
        end

        open_session do |submit_session|

          submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s + "&community[id]=" + @community.id.to_s, \
            :submit_comment => "I edited an APIS pub"

          Rails.logger.debug "--flash is: " + submit_session.flash.inspect
        end
        @publication.reload

        #Rails.logger.debug "Publication Community is " + @publication.community.name
        assert_equal @community.id, @publication.community.id, "Community is not set to default"
        #Rails.logger.debug "Community is " + @test_community.name

        #now apis should have it
        assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

        #apis board should have 1 publication, others should have 0
        apis_publications = Publication.find(:all, :conditions => { :owner_id => @apis_board.id, :owner_type => "Board" } )
        assert_equal 1, apis_publications.length, "APIS does not have 1 publication but rather, " + apis_publications.length.to_s + " publications"

        text_publications = Publication.find(:all, :conditions => { :owner_id => @text_board.id, :owner_type => "Board" } )
        assert_equal 0, text_publications.length, "Text does not have 0 publication but rather, " + text_publications.length.to_s + " publications"

        translation_publications = Publication.find(:all, :conditions => { :owner_id => @translation_board.id, :owner_type => "Board" } )
        assert_equal 0, translation_publications.length, "Translation does not have 0 publication but rather, " + translation_publications.length.to_s + " publications"

        Rails.logger.debug "APIS Board has publication"
        #vote on it
        apis_publication = apis_publications.first

        assert !apis_publication.creator_commits.empty?, "submitted publication should have creator commits"

        #find apis identifier
        apis_identifier = nil
        apis_publication.identifiers.each do |id|
          if @apis_board.controls_identifier?(id)
            apis_identifier = id
          end
        end

        assert_not_nil  apis_identifier, "Did not find the apis identifier"
        assert apis_identifier.content, "apis_identifier should have content"

        Rails.logger.debug "Found apis identifier, will vote on it"

        open_session do |apis_session|
          apis_session.post 'publications/vote/' + apis_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
            :comment => { :comment => "I agree apis is great", :user_id => @board_user.id, :publication_id => apis_identifier.publication.id, :identifier_id => apis_identifier.id, :reason => "vote" }, \
            :vote => { :publication_id => apis_identifier.publication.id.to_s, :identifier_id => apis_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @apis_board.id.to_s, :choice => "accept" }

          Rails.logger.debug "--flash is: " + apis_session.flash.inspect
      
        end

        #reload the publication to get the vote associations to go thru?
        apis_publication.reload

        vote_str = "Votes on apis are: "
        apis_publication.votes.each do |v|
          vote_str = vote_str + v.choice
        end
        Rails.logger.debug  vote_str
        Rails.logger.debug apis_publication.inspect
        Rails.logger.debug apis_publication.children.inspect

        assert_equal 1, apis_publication.votes.length, "APIS publication should have one vote"
        assert_equal 1, apis_publication.children.length, "APIS publication should have one child"

        #vote should have changed publication to approved and put to finalizer
        assert_equal "approved", apis_publication.status, "APIS publication not approved after vote"
        Rails.logger.debug "--APIS publication approved"

        apis_final_publication = apis_publication.find_finalizer_publication
        assert_equal apis_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
        Rails.logger.debug "---Finalizer has publication"

        #call finalize on publication controller

        apis_final_identifier = nil
        apis_final_publication.identifiers.each do |id|
          if @apis_board.controls_identifier?(id)
            apis_final_identifier = id
          end
        end

        apis_final_publication.reload
        apis_final_identifier.reload
        Rails.logger.info('apis_final_publication')
        Rails.logger.info(apis_final_publication.inspect)
        Rails.logger.info(apis_final_identifier.inspect)
        assert !apis_final_publication.needs_rename?, "finalizing publication should not need rename after being renamed"

        open_session do |apis_finalize_session|

          apis_finalize_session.post 'publications/' + apis_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
            :comment => 'I agree apis is great and now it is final'

          Rails.logger.debug "--flash is: " + apis_finalize_session.flash.inspect
          Rails.logger.debug "----session data is: " + apis_finalize_session.session.to_hash.inspect
          Rails.logger.debug apis_finalize_session.body
        end

        apis_final_publication.reload
        assert_equal "finalized", apis_final_publication.status, "APIS final publication not finalized"

        Rails.logger.debug "APIS committed"

        #compare the publications
        #final should have comments and votes

        apis_publication.reload
        apis_publication.log_info
        apis_final_publication.reload
        apis_final_publication.log_info
        Rails.logger.debug "Compare board with board publication"
        compare_publications(apis_publication, apis_publication)
        Rails.logger.debug "Compare board with finalizer publication"
        compare_publications(apis_publication, apis_final_publication)
        Rails.logger.debug "Compare user with finalizer publication"
        compare_publications(@creator_user.publications.first, apis_final_publication)

        @publication.destroy
      end
    end
  end

  context "for IDP2" do
    setup do
      @community = FactoryGirl.create(:master_community, :is_default => true )
      @ddb_board = FactoryGirl.create(:board, :title => 'DDbDP Editorial Board', :community => @community)

      3.times do |i|
        @ddb_board.users << FactoryGirl.create(:user)
      end

      FactoryGirl.create(:percent_decree,
                         :board => @ddb_board,
                         :trigger => 50.0,
                         :action => "approve",
                         :choices => "yes no defer")
      FactoryGirl.create(:percent_decree,
                         :board => @ddb_board,
                         :trigger => 50.0,
                         :action => "reject",
                         :choices => "reject")
      FactoryGirl.create(:count_decree,
                         :board => @ddb_board,
                         :trigger => 1.0,
                         :action => "graffiti",
                         :choices => "graffiti")

      @james = FactoryGirl.create(:user, :name => "James")

      @hgv_meta_board = FactoryGirl.create(:hgv_meta_board, :title => 'HGV metadata')
      @hgv_trans_board = FactoryGirl.create(:hgv_trans_board, :title => 'Translations')

      @hgv_meta_board.users << @james
      @hgv_trans_board.users << @james

      @submitter = FactoryGirl.create(:user, :name => "Submitter")
    end

    teardown do
      ( @ddb_board.users + [ @james, @submitter,
       @ddb_board, @hgv_meta_board, @hgv_trans_board ] ).each {|entity| entity.destroy}
    end

    context "a publication" do
      setup do
        @publication = FactoryGirl.create(:publication, :owner => @submitter, :creator => @submitter, :status => "new", :community => @community)

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      end

      teardown do
        @publication.reload
        @publication.destroy
      end

      context "submitted with only APIS modifications" do
        setup do
          @new_apis = APISIdentifier.new_from_template(@publication)
          @publication.reload
          @publication.submit
        end

        should "exist" do
          assert true
        end
      end

      context "submitted with only DDB modifications" do
        setup do
          @new_ddb = DDBIdentifier.new_from_template(@publication)
          @publication.reload
          @publication.submit
        end

        should "be copied to the DDB board" do
          assert_equal @publication, @ddb_board.publications.first.parent
          assert_equal @publication.children, @ddb_board.publications
          assert_equal @ddb_board, @publication.children.first.owner
        end

        should "not be copied to the HGV boards" do
          assert_equal 0, @hgv_meta_board.publications.length
          assert_equal 0, @hgv_trans_board.publications.length
        end

        context "voted 'approve'" do
          setup do
            @new_ddb_submitted = @ddb_board.publications.first.identifiers.first
            @new_ddb_submitted_id = @new_ddb_submitted.id
            generate_board_votes_for_action(@ddb_board, "approve", @new_ddb_submitted)
          end

          should "have two 'approve' votes" do
            assert_equal 2, @new_ddb_submitted.votes.select {|v| %{yes no defer}.include?(v.choice)}.length
          end

          should "be copied to a finalizer" do
            assert_equal 1, @ddb_board.publications.first.children.length
            finalizing_publication = @ddb_board.publications.first.children.first
            assert_equal "finalizing", finalizing_publication.status
            assert_equal User, finalizing_publication.owner.class
          end
        end # approve

        context "voted 'reject'" do
          setup do
            @new_ddb_submitted = @ddb_board.publications.first.identifiers.first
            generate_board_votes_for_action(@ddb_board, "reject", @new_ddb_submitted)
          end

          should "have two 'reject' vote comments" do
            # assert_equal 2, @new_ddb_submitted.votes.select {|v| %{reject}.include?(v.choice)}.length
          end

          should "be copied back to the submitter" do
          end

          should "be deleted from editorial board" do
            assert !Publication.exists?(@new_ddb_submitted_id)
          end
        end # reject
      end # DDB-only
    end
  end
end
