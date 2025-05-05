require 'test_helper'
require 'ddiff'
require 'thwait'

class SosolWorkflowTest < ActionDispatch::IntegrationTest
  def generate_board_vote_for_decree(_board, decree, identifier, user)
    FactoryBot.create(:vote,
                      publication_id: identifier.publication.id,
                      identifier_id: identifier.id,
                      user: user,
                      choice: (decree.get_choice_array)[rand(
                        decree.get_choice_array.size
                      )])
  end

  def generate_board_votes_for_action(board, action, identifier)
    decree = board.decrees.detect { |d| d.action == action }
    vote_count = 0
    if decree.tally_method == Decree::TALLY_METHODS[:percent]
      while ((vote_count.to_f / decree.board.users.length) * 100) < decree.trigger
        generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
        vote_count += 1
      end
    elsif decree.tally_method == Decree::TALLY_METHODS[:count]
      while vote_count.to_f < decree.trigger
        generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
        vote_count += 1
      end
    end
  end

  def compare_publications(a, b)
    pubs_are_matched = true
    a.identifiers.each do |aid|
      id_has_match = false
      b.identifiers.each do |bid|
        if aid.class.to_s == bid.class.to_s && aid.title == bid.title
          if aid.xml_content == bid.xml_content
            id_has_match = true
            Rails.logger.debug 'Identifier match found'
          else
            Rails.logger.debug { "#{a.title} has nill #{aid.class} identifier" } if aid.xml_content.nil?
            Rails.logger.debug { "#{b.title} has nill #{bid.class} identifier" } if bid.xml_content.nil?
            Rails.logger.debug { "Identifier diffs for #{a.title} #{b.title} #{aid.class} #{aid.title}" }
            log_diffs(aid.xml_content.to_s, bid.xml_content.to_s)
            # Rails.logger.debug "full xml a " + aid.xml_content
            # Rails.logger.debug "full xml b " + bid.xml_content
          end
        end
      end

      unless id_has_match
        pubs_are_matched = false
        Rails.logger.debug { "--Mis matched publication. Id #{aid.title} #{aid.class} is different" }
      end
    end

    Rails.logger.debug 'Publications are matched' if pubs_are_matched
  end

  def log_diffs(a, b)
    a_to_b_diff = a.diff(b)

    plus_str = ''
    minus_str = ''
    a_to_b_diff.diffs.each do |d|
      d.each do |mod|
        if mod[0] == '+'
          plus_str += mod[2].chr
        else
          minus_str += mod[2].chr
        end
      end
    end

    Rails.logger.debug { "added #{plus_str}" }
    Rails.logger.debug { "removed #{minus_str}" }
  end
end

class SosolWorkflowTest < ActionDispatch::IntegrationTest
  context 'for idp3' do
    context 'sosol testing' do
      setup do
        Rails.logger.level = 0
        Rails.logger.debug 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx sosol testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        # a user to put on the boards
        @board_user = FactoryBot.create(:user, name: 'board_man_bob', email: 'bob@example.com')
        @board_user_2 = FactoryBot.create(:user, name: 'board_man_alice')
        # a user to submit publications
        @creator_user = FactoryBot.create(:user, name: 'creator_bob', email: 'bobcreator@example.com')
        # an end user to recieve the "finalized" publication
        @end_user = FactoryBot.create(:user, name: 'end_bob')

        # set up the boards, and vote
        @meta_board = FactoryBot.create(:hgv_meta_board, title: 'meta')

        # the board memeber
        @meta_board.users << @board_user

        # the vote
        @meta_decree = FactoryBot.create(:count_decree,
                                         board: @meta_board,
                                         trigger: 1.0,
                                         action: 'approve',
                                         choices: 'ok')
        @meta_board.decrees << @meta_decree

        # the mailer
        @mailer1 = FactoryBot.create(:emailer, board: @meta_board, when_to_send: 'submitted',
                                               send_to_owner: true, send_to_all_board_members: false, message: 'Message Text', subject: 'Submitted to Meta')
        @mailer2 = FactoryBot.create(:emailer, board: @meta_board, when_to_send: 'submitted',
                                               send_to_owner: false, send_to_all_board_members: true, message: 'Board Message Text', subject: 'Board Member Alert')
        @meta_board.emailers << @mailer1
        @meta_board.emailers << @mailer2

        @text_board = FactoryBot.create(:board, title: 'text')
        # the board memeber
        @text_board.users << @board_user
        @text_board.users << @board_user_2
        # the vote
        @text_decree = FactoryBot.create(:count_decree,
                                         board: @text_board,
                                         trigger: 1.0,
                                         action: 'approve',
                                         choices: 'ok')
        @text_board.decrees << @text_decree

        @translation_board = FactoryBot.create(:hgv_trans_board, title: 'translation')

        # the board memeber
        @translation_board.users << @board_user
        # the vote
        @translation_decree = FactoryBot.create(:count_decree,
                                                board: @translation_board,
                                                trigger: 1.0,
                                                action: 'approve',
                                                choices: 'ok')
        @translation_board.decrees << @translation_decree

        # set board order
        @meta_board.rank = 1
        @text_board.rank = 2
        @translation_board.rank = 3
      end

      teardown do
        count = 0
        [@board_user, @board_user_2, @creator_user, @end_user, @meta_board, @text_board,
         @translation_board].reverse_each do |entity|
          count += 1
          # assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil."
          unless entity.nil?
            entity.reload
            entity.destroy
          end
        end
      end

      should 'user creates and submits publication to sosol' do
        Rails.logger.debug 'BEGIN TEST: user creates and submits publication to sosol'

        assert_not_equal nil, @meta_board, 'Meta board not created'
        assert_not_equal nil, @text_board, 'Text board not created'
        assert_not_equal nil, @translation_board, 'Translation board not created'

        # create a publication with a session
        open_session do |publication_session|
          # publication_session.data
          Rails.logger.debug '---Create A New Publication---'
          # publication_session.post 'publications/create_from_templates', :session => { :user_id => @creator_user.id }

          publication_session.post '/publications/create_from_templates',
                                   params: { test_user_id: @creator_user.id.to_s }

          Rails.logger.debug { "--flash is: #{publication_session.flash.inspect}" }

          @publication = @creator_user.publications.first

          @publication.log_info
        end

        Rails.logger.debug '---Publication Created---'
        Rails.logger.debug { "--identifier count is: #{@publication.identifiers.count}" }

        an_array = @publication.identifiers
        Rails.logger.debug { "--identifier length via array is: #{an_array.length}" }

        Rails.logger.debug { "---Identifiers for publication #{@publication.title} are:" }

        @publication.identifiers.each do |pi|
          Rails.logger.debug '-identifier-'
          Rails.logger.debug { "title is: #{pi.title}" }
          Rails.logger.debug { "was it modified?: #{pi.modified?}" }
          Rails.logger.debug 'xml:'
          Rails.logger.debug pi.xml_content
        end

        deliveries_before = ActionMailer::Base.deliveries.size
        open_session do |submit_session|
          submit_session.post "/publications/#{@publication.id}/submit/",
                              params: { test_user_id: @creator_user.id.to_s, submit_comment: 'I made a new pub' }

          Rails.logger.debug { "--flash is: #{submit_session.flash.inspect}" }
        end
        @publication.reload

        # Rails.logger.debug "Publication Community is " + @publication.community.name
        assert_nil @publication.community, 'Community is not NIL but should be for a SOSOL publication'
        # Rails.logger.debug "Community is " + @test_community.name

        # now meta should have it
        assert_equal 'submitted', @publication.status,
                     "Publication status not submitted #{@publication.community_id} id "
        deliveries_after = ActionMailer::Base.deliveries.size
        assert_equal 2, deliveries_after - deliveries_before
        owner_email = ActionMailer::Base.deliveries.first
        assert_equal 'Submitted to Meta', owner_email.subject
        assert_equal 'bobcreator@example.com', owner_email.to[0]
        board_email = ActionMailer::Base.deliveries.last
        assert_equal 'Board Member Alert', board_email.subject
        assert_equal 'bob@example.com', board_email.to[0]

        # meta board should have 1 publication, others should have 0
        meta_publications = Publication.where(owner_id: @meta_board.id, owner_type: 'Board')
        assert_equal 1, meta_publications.length,
                     "Meta does not have 1 publication but rather, #{meta_publications.length} publications"

        text_publications = Publication.where(owner_id: @text_board.id, owner_type: 'Board')
        assert_equal 0, text_publications.length,
                     "Text does not have 0 publication but rather, #{text_publications.length} publications"

        translation_publications = Publication.where(owner_id: @translation_board.id, owner_type: 'Board')
        assert_equal 0, translation_publications.length,
                     "Translation does not have 0 publication but rather, #{translation_publications.length} publications"

        Rails.logger.debug 'Meta Board has publication'
        # vote on it
        meta_publication = meta_publications.first

        assert_not meta_publication.creator_commits.empty?, 'submitted publication should have creator commits'

        # find meta identifier
        meta_identifier = nil
        meta_publication.identifiers.each do |id|
          meta_identifier = id if @meta_board.controls_identifier?(id)
        end

        assert_not_nil meta_identifier, 'Did not find the meta identifier'
        assert meta_identifier.content, 'meta_identifier should have content'

        Rails.logger.debug 'Found meta identifier, will vote on it'

        open_session do |meta_session|
          meta_session.post "/publications/vote/#{meta_publication.id}",
                            params: { test_user_id: @board_user.id.to_s, comment: { comment: 'I agree meta is great', user_id: @board_user.id, publication_id: meta_identifier.publication.id, identifier_id: meta_identifier.id, reason: 'vote' }, \
                                      vote: { publication_id: meta_identifier.publication.id.to_s, identifier_id: meta_identifier.id.to_s, user_id: @board_user.id.to_s, board_id: @meta_board.id.to_s, choice: 'ok' } }

          Rails.logger.debug { "--flash is: #{meta_session.flash.inspect}" }
        end

        # reload the publication to get the vote associations to go thru?
        meta_publication.reload

        vote_str = 'Votes on meta are: '
        meta_publication.votes.each do |v|
          vote_str += v.choice
        end
        Rails.logger.debug vote_str
        Rails.logger.debug meta_publication.inspect
        Rails.logger.debug meta_publication.children.inspect

        assert_equal 1, meta_publication.votes.length, 'Meta publication should have one vote'
        assert_equal 1, meta_publication.children.length, 'Meta publication should have one child'

        # vote should have changed publication to approved and put to finalizer
        assert_equal 'approved', meta_publication.status, 'Meta publication not approved after vote'
        Rails.logger.debug '--Meta publication approved'

        meta_final_publication = meta_publication.find_finalizer_publication
        assert_equal('finalizing', meta_final_publication.status, "Board user's publication is not for finalizing")
        Rails.logger.debug '---Finalizer has publication'

        # call finalize on publication controller

        meta_final_identifier = nil
        meta_final_publication.identifiers.each do |id|
          meta_final_identifier = id if @meta_board.controls_identifier?(id)
        end

        assert meta_final_identifier.content, "finalizing publication's identifier should have content"
        assert_predicate meta_final_publication, :needs_rename?,
                         'finalizing publication should need rename before being renamed'

        Rails.logger.info('meta_final_identifier')
        Rails.logger.info(meta_final_identifier.inspect)

        # Mock transform
        Epidocinator.any_instance.stubs(:apply_xsl_transform).returns('')

        # do rename
        open_session do |meta_rename_session|
          meta_rename_session.patch "/publications/#{meta_final_publication.id}/hgv_meta_identifiers/#{meta_final_identifier.id}/rename/",
                                    params: { test_user_id: meta_final_publication.owner.id.to_s,
                                              new_name: 'papyri.info/hgv/9999999999' }
        end

        meta_final_publication.reload
        meta_final_identifier.reload
        Rails.logger.info('meta_final_publication')
        Rails.logger.info(meta_final_publication.inspect)
        Rails.logger.info(meta_final_identifier.inspect)
        assert_not meta_final_publication.needs_rename?,
                   'finalizing publication should not need rename after being renamed'

        canonical_before_finalize = Repository.new.get_head('master')

        open_session do |meta_finalize_session|
          meta_finalize_session.post "/publications/#{meta_final_publication.id}/finalize/",
                                     params: { test_user_id: meta_final_publication.owner.id.to_s,
                                               comment: 'I agree meta is great and now it is final' }

          Rails.logger.debug { "--flash is: #{meta_finalize_session.flash.inspect}" }
          Rails.logger.debug { "----session data is: #{meta_finalize_session.session.to_hash.inspect}" }
          Rails.logger.debug meta_finalize_session.body
        end

        meta_final_publication.reload
        assert_equal 'finalized', meta_final_publication.status, 'Meta final publication not finalized'

        canonical_after_finalize = Repository.new.get_head('master')
        assert_not_equal canonical_before_finalize, canonical_after_finalize,
                         'Meta finalization should update canonical master'

        Rails.logger.debug 'Meta committed'

        # compare the publications
        # final should have comments and votes

        meta_publication.reload
        meta_publication.log_info
        meta_final_publication.reload
        meta_final_publication.log_info
        Rails.logger.debug 'Compare board with board publication'
        compare_publications(meta_publication, meta_publication)
        Rails.logger.debug 'Compare board with finalizer publication'
        compare_publications(meta_publication, meta_final_publication)
        Rails.logger.debug 'Compare user with finalizer publication'
        compare_publications(@creator_user.publications.first, meta_final_publication)

        #=================================TEXT BOARD==========================================
        # now text board should have it

        # meta board should have 1 publication
        meta_publications = Publication.where(owner_id: @meta_board.id, owner_type: 'Board')
        assert_equal 1, meta_publications.length,
                     "Meta does not have 1 publication but rather, #{meta_publications.length} publications"

        # text board should have 1 publication
        text_publications = Publication.where(owner_id: @text_board.id, owner_type: 'Board')
        assert_equal 1, text_publications.length,
                     "Text does not have 0 publication but rather, #{text_publications.length} publications"

        # translation board should have 0 publication
        translation_publications = Publication.where(owner_id: @translation_board.id, owner_type: 'Board')
        assert_equal 0, translation_publications.length,
                     "Translation does not have 0 publication but rather, #{translation_publications.length} publications"

        # vote on it
        text_publication = text_publications.first

        # find text identifier
        text_identifier = nil
        text_publication.identifiers.each do |id|
          text_identifier = id if @text_board.controls_identifier?(id)
        end

        assert_not_nil text_identifier, 'Did not find the text identifier'

        Rails.logger.debug 'Found text identifier, will vote on it'

        open_session do |text_session|
          text_session.post "/publications/vote/#{text_publication.id}",
                            params: { test_user_id: @board_user.id.to_s, comment: { comment: 'I agree text is great', user_id: @board_user.id, publication_id: text_identifier.publication.id, identifier_id: text_identifier.id, reason: 'vote' }, \
                                      vote: { publication_id: text_identifier.publication.id.to_s, identifier_id: text_identifier.id.to_s, user_id: @board_user.id.to_s, board_id: @text_board.id.to_s, choice: 'ok' } }
          Rails.logger.debug { "--flash is: #{text_session.flash.inspect}" }
        end

        # reload the publication to get the vote associations to go thru?
        text_publication.reload

        assert_equal 1, text_publication.votes.length, 'Text publication should have one vote'
        Rails.logger.debug 'After text publication voting, origin has children:'
        Rails.logger.debug text_publication.origin.children.inspect
        assert_equal 1, text_publication.children.length, 'Text publication should have one child'

        # vote should have changed publication to approved and put to finalizer
        assert_equal 'approved', text_publication.status, 'Text publication not approved after vote'
        Rails.logger.debug '--Text publication approved'

        text_final_publication = text_publication.find_finalizer_publication

        assert_not_nil text_final_publication, 'Publication does not have text finalizer'
        Rails.logger.debug '---Finalizer has text publication'

        text_final_identifier = nil
        text_final_publication.identifiers.each do |id|
          text_final_identifier = id if @text_board.controls_identifier?(id)
        end
        assert_not_nil text_final_identifier, 'Finalizer does not have controlled identifier'

        assert_predicate text_final_publication, :needs_rename?,
                         'finalizing publication should need rename before being renamed'

        # try to finalize without rename
        open_session do |text_finalize_session|
          text_finalize_session.post "/publications/#{text_final_publication.id}/finalize/",
                                     params: { test_user_id: text_final_publication.owner.id.to_s,
                                               comment: 'I agree text is great and now it is final' }

          Rails.logger.debug { "--flash is: #{text_finalize_session.flash.inspect}" }
          Rails.logger.debug { "----session data is: #{text_finalize_session.session.to_hash.inspect}" }
          Rails.logger.debug text_finalize_session.body
        end

        text_final_publication.reload
        assert_not_equal 'finalized', text_final_publication.status,
                         'Text final publication finalized when it should be blocked by rename guard'

        # do rename
        open_session do |text_rename_session|
          text_rename_session.patch "/publications/#{text_final_publication.id}/ddb_identifiers/#{text_final_identifier.id}/rename/",
                                    params: { test_user_id: text_final_publication.owner.id.to_s,
                                              new_name: 'papyri.info/ddbdp/bgu;1;999', set_dummy_header: false }
        end

        text_final_publication.reload
        assert_not text_final_publication.needs_rename?,
                   'finalizing publication should not need rename after being renamed'

        other_finalizer = (@text_board.users - [text_final_publication.owner]).first
        assert_not_equal other_finalizer, text_final_publication.owner,
                         'Other finalizer should not be current finalizer'

        publication_head_original = text_final_publication.head
        # do make-me-finalizer now that we've renamed
        open_session do |mmf_session|
          mmf_session.post "/publications/#{text_publication.id}/become_finalizer",
                           params: { test_user_id: other_finalizer.id.to_s }
          Rails.logger.debug { "--MMF flash is: #{mmf_session.flash.inspect}" }
          Rails.logger.debug { "----MMF session data is: #{mmf_session.session.to_hash.inspect}" }
          Rails.logger.debug mmf_session.body
        end

        assert_raise ActiveRecord::RecordNotFound,
                     'Original finalization publication should be destroyed by make-me-finalizer process' do
          Publication.find(text_final_publication.id)
        end
        text_final_publication = text_publication.find_finalizer_publication
        assert_equal other_finalizer, text_final_publication.owner,
                     'Other finalizer should be finalizer after make-me-finalizer'
        assert_not text_final_publication.needs_rename?,
                   'finalizing publication should not need rename after being renamed then make-me-finalizered'
        assert_equal publication_head_original, text_final_publication.head,
                     'New finalizer publication should have the same commit history as the original'

        canonical_before_finalize = Repository.new.get_head('master')
        # actually finalize
        open_session do |text_finalize_session|
          text_finalize_session.post "/publications/#{text_final_publication.id}/finalize/",
                                     params: { test_user_id: text_final_publication.owner.id.to_s,
                                               comment: 'I agree text is great and now it is final' }

          Rails.logger.debug { "--flash is: #{text_finalize_session.flash.inspect}" }
          Rails.logger.debug { "----session data is: #{text_finalize_session.session.to_hash.inspect}" }
          Rails.logger.debug text_finalize_session.body

          Rails.logger.debug { "--flash is: #{text_finalize_session.flash.inspect}" }
        end

        text_final_publication.reload
        assert_equal 'finalized', text_final_publication.status, 'Text final publication not finalized'

        canonical_after_finalize = Repository.new.get_head('master')
        assert_not_equal canonical_before_finalize, canonical_after_finalize,
                         'Text finalization should update canonical master'

        Rails.logger.debug '---Text publication Finalized'

        current_creator_publication = @creator_user.publications.first
        current_creator_publication.reload

        current_creator_publication.log_info

        text_final_publication.reload
        text_final_publication.log_info

        # assert_equal @meta_board.publications.first.origin, @publication, "Meta board does not have publications"
        @publication.destroy
      end
    end
  end

  context 'for IDP2' do
    setup do
      @ddb_board = FactoryBot.create(:board, title: 'DDbDP Editorial Board')

      3.times do |_i|
        @ddb_board.users << FactoryBot.create(:user)
      end

      FactoryBot.create(:percent_decree,
                        board: @ddb_board,
                        trigger: 50.0,
                        action: 'approve',
                        choices: 'yes no defer')
      FactoryBot.create(:percent_decree,
                        board: @ddb_board,
                        trigger: 50.0,
                        action: 'reject',
                        choices: 'reject')
      FactoryBot.create(:count_decree,
                        board: @ddb_board,
                        trigger: 1.0,
                        action: 'graffiti',
                        choices: 'graffiti')

      @james = FactoryBot.create(:user, name: 'James')

      @hgv_meta_board = FactoryBot.create(:hgv_meta_board, title: 'HGV metadata')
      @hgv_trans_board = FactoryBot.create(:hgv_trans_board, title: 'Translations')

      @hgv_meta_board.users << @james
      @hgv_trans_board.users << @james

      @submitter = FactoryBot.create(:user, name: 'Submitter', email: 'submitter@example.com')
    end

    teardown do
      Rails.logger.info("Running IDP2 context teardown in thread: #{Thread.current.object_id}")
      (@ddb_board.users + [@james, @submitter,
                           @ddb_board, @hgv_meta_board, @hgv_trans_board]).each(&:destroy)
    end

    context 'a publication' do
      setup do
        @publication = FactoryBot.create(:publication, owner: @submitter, creator: @submitter, status: 'new')

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      end

      teardown do
        # @publication.reload
        # @publication.destroy
      end

      context 'with only DDB modifications' do
        setup do
          @new_ddb = DDBIdentifier.new_from_template(@publication)
          @publication.reload
        end

        should 'not be able to race with multiple submissions' do
          Rails.logger.info("submission race on pub: #{@publication.inspect}")
          assert Publication.exists?(@publication.id)
          assert User.exists?(@publication.owner.id)
          submit_publication_id = @publication.id.to_s
          submitter = @publication.owner.id.to_s

          new_active_threads = []

          new_active_threads << Thread.new do
            Rails.application.executor.wrap do
              open_session do |submit_session|
                submit_session.post "/publications/#{submit_publication_id}/submit",
                                    params: { test_user_id: submitter }
              rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
                Rails.logger.info("#{e.class} inside submission thread 1")
              end
            ensure
              # The new thread gets a new AR connection, so we should
              # always close it and flush logs before we terminate
              Rails.logger.debug('submit race submit 1 finished')
              Rails.logger.flush
            end
          end

          new_active_threads << Thread.new do
            Rails.application.executor.wrap do
              open_session do |submit_session|
                submit_session.post "/publications/#{submit_publication_id}/submit",
                                    params: { test_user_id: submitter }
              rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
                Rails.logger.info("#{e.class} inside submit thread 2")
              end
            ensure
              # The new thread gets a new AR connection, so we should
              # always close it and flush logs before we terminate
              Rails.logger.debug('submit race submit 2 finished')
              Rails.logger.flush
            end
          end

          Rails.logger.debug { "submit race threadwaiting on: #{new_active_threads.inspect}" }
          Rails.logger.flush
          # new_active_threads.each(&:join)
          ThreadsWait.all_waits(*new_active_threads)
          Rails.logger.debug 'submit race threadwaiting done'
          Rails.logger.flush

          @publication.reload
          assert_equal 1, @publication.children.length,
                       'submitted publication should only have one child after submissions'
          assert_equal 1, @publication.all_children.length,
                       'submitted publication should only have one child after submissions'
          assert_equal 'submitted', @publication.status,
                       'submitted publication should have status "submitted" after submissions'
          Rails.logger.debug 'submit race assertions done'
          Rails.logger.flush
        end
      end

      context 'submitted with only DDB modifications' do
        setup do
          @new_ddb = DDBIdentifier.new_from_template(@publication)
          @publication.reload
          @publication.submit
        end

        should 'be copied to the DDB board' do
          assert_equal @publication, @ddb_board.publications.first.parent
          assert_equal @publication.children, @ddb_board.publications
          assert_equal @ddb_board, @publication.children.first.owner
        end

        should 'not be copied to the HGV boards' do
          assert_equal 0, @hgv_meta_board.publications.length
          assert_equal 0, @hgv_trans_board.publications.length
        end

        context "voted 'approve'" do
          setup do
            @new_ddb_submitted = @ddb_board.publications.first.identifiers.first
            @new_ddb_submitted_id = @new_ddb_submitted.id
            generate_board_votes_for_action(@ddb_board, 'approve', @new_ddb_submitted)
          end

          should "have two 'approve' votes" do
            assert_equal 2, @new_ddb_submitted.votes.count { |v| %(yes no defer).include?(v.choice) }
          end

          should 'be copied to a finalizer' do
            assert_equal 1, @ddb_board.publications.first.children.length
            finalizing_publication = @ddb_board.publications.first.children.first
            assert_equal 'finalizing', finalizing_publication.status
            assert_equal User, finalizing_publication.owner.class
          end

          should 'be copyable to another finalizer' do
            assert_equal 1, @ddb_board.publications.first.children.length, 'DDB publication should have one child'
            finalizing_publication = @ddb_board.publications.first.children.first
            original_finalizer = finalizing_publication.owner
            assert_equal 'finalizing', finalizing_publication.status
            assert_equal User, original_finalizer.class
            different_finalizer = (@ddb_board.users - [original_finalizer]).first
            assert_not_equal original_finalizer, different_finalizer

            Rails.logger.info("MMF on pub: #{@ddb_board.publications.first.inspect}")
            open_session do |make_me_finalizer_session|
              make_me_finalizer_session.post "/publications/#{@ddb_board.publications.first.id}/become_finalizer",
                                             params: { test_user_id: different_finalizer.id.to_s }
            end

            mmf_finalizing_publication = @ddb_board.publications.first.children.first
            current_finalizer = mmf_finalizing_publication.owner
            assert_not_equal original_finalizer, current_finalizer,
                             'Current finalizer should not be the same as the original finalizer'
            assert_equal 1, @ddb_board.publications.first.children.length,
                         'DDB publication should only have one child after finalizer copy'
          end

          should 'not race during make-me-finalizer' do
            assert_not_nil @ddb_board
            @ddb_board.reload
            assert_not_nil @ddb_board
            assert Board.exists?(@ddb_board.id)
            assert_equal 1, @ddb_board.publications.first.children.length, 'DDB publication should have one child'
            finalizing_publication = @ddb_board.publications.first.children.first
            original_finalizer = finalizing_publication.owner
            assert_equal User, original_finalizer.class
            assert_equal 'finalizing', finalizing_publication.status
            different_finalizer = (@ddb_board.users - [original_finalizer]).first.id.to_s
            different_finalizer_2 = (@ddb_board.users - [original_finalizer]).last.id.to_s
            assert_not_equal original_finalizer.id.to_s, different_finalizer
            assert_not_equal different_finalizer, different_finalizer_2
            assert User.exists?(different_finalizer)
            assert User.exists?(different_finalizer_2)

            mmf_publication = @ddb_board.publications.first
            mmf_publication_id = mmf_publication.id.to_s
            mmf_publication_owner_id = mmf_publication.owner.id.to_s

            Rails.logger.info("MMF race on pub: #{mmf_publication.inspect}")
            Rails.logger.info("MMF race parent thread id: #{Thread.current.object_id}")
            Thread.report_on_exception = false

            new_active_threads = []

            new_active_threads << Thread.new do
              Rails.application.executor.wrap do
                Rails.logger.info("Starting MMF race thread 1: #{Thread.current.object_id}")
                Thread.current.report_on_exception = false
                open_session do |make_me_finalizer_session|
                  assert Publication.exists?(mmf_publication_id), 'MMF publication should exist in thread 1'
                  assert User.exists?(different_finalizer), 'MMF finalizer should exist in thread 1'
                  assert Board.exists?(mmf_publication_owner_id), 'MMF board should exist in thread 1'
                  make_me_finalizer_session.post "/publications/#{mmf_publication_id}/become_finalizer",
                                                 params: { test_user_id: different_finalizer }
                rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
                  Rails.logger.info("#{e.class} inside MMF thread 1")
                end
              ensure
                # The new thread gets a new AR connection, so we should
                # always close it and flush logs before we terminate
                Rails.logger.debug('MMF race become_finalizer 1 finished')
                Rails.logger.flush
              end
            end

            new_active_threads << Thread.new do
              Rails.application.executor.wrap do
                Rails.logger.info("Starting MMF race thread 2: #{Thread.current.object_id}")
                Thread.current.report_on_exception = false
                open_session do |make_me_finalizer_session|
                  assert Publication.exists?(mmf_publication_id), 'MMF publication should exist in thread 2'
                  assert User.exists?(different_finalizer_2), 'MMF finalizer should exist in thread 2'
                  assert Board.exists?(mmf_publication_owner_id), 'MMF board should exist in thread 2'
                  make_me_finalizer_session.post "/publications/#{mmf_publication_id}/become_finalizer",
                                                 params: { test_user_id: different_finalizer_2 }
                rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
                  Rails.logger.info("#{e.class} inside MMF thread 2")
                end
              ensure
                # The new thread gets a new AR connection, so we should
                # always close it and flush logs before we terminate
                Rails.logger.debug('MMF race become_finalizer 2 finished')
                Rails.logger.flush
              end
            end

            Rails.logger.debug { "MMF race threadwaiting on: #{new_active_threads.inspect}" }
            Rails.logger.flush
            # new_active_threads.each(&:join)
            ThreadsWait.all_waits(*new_active_threads)
            Rails.logger.debug 'MMF race threadwaiting done'
            Rails.logger.flush

            @ddb_board.reload
            assert_equal 1, @ddb_board.publications.first.children.length,
                         'DDB publication should only have one child after finalizer copy'
            mmf_finalizing_publication = @ddb_board.publications.first.children.first
            current_finalizer = mmf_finalizing_publication.owner
            assert_not_equal original_finalizer, current_finalizer,
                             'Current finalizer should not be the same as the original finalizer'
            Rails.logger.debug 'MMF race assertions done'
            Rails.logger.flush
          end
        end

        context "voted 'reject'" do
          setup do
            @new_ddb_submitted = @ddb_board.publications.first.identifiers.first
            generate_board_votes_for_action(@ddb_board, 'reject', @new_ddb_submitted)
          end

          should "have two 'reject' vote comments" do
            # assert_equal 2, @new_ddb_submitted.votes.select {|v| %{reject}.include?(v.choice)}.length
          end

          should 'be copied back to the submitter' do
          end

          should 'be deleted from editorial board' do
            assert_not Publication.exists?(@new_ddb_submitted_id)
          end
        end
      end
    end
  end
end
