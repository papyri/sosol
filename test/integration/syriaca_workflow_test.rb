# encoding: utf-8
require 'test_helper'
require 'ddiff'

#require File.dirname(__FILE__) + '/session_set_controller'

=begin
This file tests the Pass Through Community workflow.

The Pass Through Community workflow is similar to a Master Community workflow (or the default SoSOL 
workflow) except that the publication/identifiers are not committed to the canon on finalize. 
Instead the changes made by the finalizer are copied back to the submitters origin publication.
Once the publication has been vetted by all the community boards, the "committed" version 
is either (a) submitted to the next community or (b) sent to an external agent.

=end

if Sosol::Application.config.site_identifiers.split(',').include?('SyriacaIdentifier')
  class SyriacaWorkflowTest < ActionController::IntegrationTest
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

  class SyriacaWorkflowTest < ActionController::IntegrationTest
    context "for community" do
      context "community testing" do
        setup do
          #Rails.logger.level = :debug
          Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx community testing setup xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"


          #users to put on the boards
          @disperser_user = FactoryGirl.create(:user, :name => "disperser")
          @board_user = FactoryGirl.create(:user, :name => "board_man_freaky_bob")
          @board_user2 = FactoryGirl.create(:user, :name => "board_woman_jane")
          @board_user3 = FactoryGirl.create(:user, :name => "board_woman_sally")

          #a user to submit publications
          @creator_user = FactoryGirl.create(:user, :name => "creator_freaky_syriacan_editor")

          #master board user
          @master_user = FactoryGirl.create(:user, :name => "master_freaky_bob")

          #community admin
          @community_admin = FactoryGirl.create(:user, :name => "community_admin")

          #a general member in the community
          @community_user = FactoryGirl.create(:user, :name => "community_freaky_bob")


          #mock an agent for agent based pass to test
          @agent = stub("mockagent")
          @client = stub("mockclient")
          @client.stubs(:post_content).returns(201)
          @client.stubs(:get_transformation).returns(nil)
          AgentHelper.stubs(:get_client).with(@agent).returns(@client)
          AgentHelper.stubs(:agent_of).with('mockagent').returns(@agent)

          # a complete integration test would pass to a test instance of the flask-github-proxy
          #:pass_to => "https://github.com/perseids-project/srophe-app-data")
          @test_agent_community = FactoryGirl.create(:pass_through_community,
                                               :name => "test_syriaca_community",
                                               :friendly_name => "testy agent",
                                               :allows_self_signup => true,
                                               :description => "a syriaca comunity for testing",
                                               :pass_to => "mockagent")

          @test_agent_community.members << @community_user
          @test_agent_community.admins << @community_admin

          @test_agent_board = FactoryGirl.create(:syriaca_community_board, :title => "SyriacaTestBoard", :community_id => @test_agent_community.id, :max_assignable => 1, :requires_assignment => true)
          @test_agent_board.users << @board_user
          @test_agent_board.users << @board_user2
          @test_agent_board.users << @board_user3
          @default_finalizer = @board_user3
          @test_agent_board.finalizer_user = @default_finalizer
          @test_agent_board.save
          @test_agent_decree = FactoryGirl.create(:count_decree,
                                            :board => @test_agent_board,
                                            :trigger => 1.0,
                                            :action => "approve",
                                            :choices => "ok")
          @test_agent_board.decrees << @test_agent_decree
          @place_file = File.read(File.join(File.dirname(__FILE__), 'data', '1000.xml'))

          @test_person_community = FactoryGirl.create(:pass_through_community,
                                               :name => "test_syriaca_person_community",
                                               :friendly_name => "testy agent",
                                               :allows_self_signup => true,
                                               :description => "a syriaca person comunity for testing",
                                               :pass_to => "mockagent")

          @test_person_community.members << @community_user
          @test_person_community.admins << @community_admin
          @test_disperse_board = FactoryGirl.create(:syriaca_person_community_board, :title => "SyriacaTestDispersalBoard", :community_id => @test_person_community.id, :skip_finalize => true, :rank => 1)
          @test_disperse_board.users << @disperser_user
          @test_disperse_decree = FactoryGirl.create(:count_decree,
                                            :board => @test_disperse_board,
                                            :trigger => 1.0,
                                            :action => "approve",
                                            :choices => "ok")

          @test_person_board = FactoryGirl.create(:syriaca_person_community_board, :title => "SyriacaTestPersonBoard", :community_id => @test_person_community.id, :rank => 2, :max_assignable => 1, :requires_assignment => true)
          @test_person_board.users << @board_user
          @test_person_decree = FactoryGirl.create(:count_decree,
                                            :board => @test_person_board,
                                            :trigger => 1.0,
                                            :action => "approve",
                                            :choices => "ok")
          @test_agent_board.decrees << @test_agent_decree
          @person_file = File.read(File.join(File.dirname(__FILE__), 'data', '1002.xml'))
        
          @mock_data  = File.read(File.join(File.dirname(__FILE__), 'data', 'srophe_processed.xml'))
          @ppagent = stub("mockagent2")
          @ppclient = stub("mockclient2")
          @ppclient.stubs(:post_content).returns(@mock_data)
          @ppclient.stubs(:get_transformation).returns(nil)
          @ppclient.stubs(:to_s).returns("mock srophe agent")
          AgentHelper.stubs(:agent_of).with('http://syriaca.org/place/1000').returns(@ppagent)
          AgentHelper.stubs(:agent_of).with('http://syriaca.org/person/1002').returns(@ppagent)
          AgentHelper.stubs(:get_client).with(@ppagent).returns(@ppclient)


          Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz syriaca community testing setup complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
        end

        teardown do
          Rails.logger.debug "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx syriaca community testing teardown begin xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          begin
            ActiveRecord::Base.connection_pool.with_connection do |conn|
              count = 0
              [ @board_user, @creator_user, @master_user, @community_user, @test_agent_community, @board_user2, @board_user3, @test_disperse_board, @disperser_user ].each do |entity|
                count = count + 1
                #assert_not_equal entity, nil, count.to_s + " cant be destroyed since it is nil."
                unless entity.nil?
                  entity.reload
                  entity.destroy
                end
              end
            end
          end
          Rails.logger.debug "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz syriaca community testing teardown complete zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
        end

        should "user creates and submits publication to community"  do
          Rails.logger.debug "BEGIN TEST: user creates and submits publication to community"

          assert_not_equal nil, @test_agent_community, "Community not created"

          #create a publication with a session
          Rails.logger.debug "---Create A New Publication---"
          open_session do |submit_session|
            #submit_session.post 'api/v1/xmlitems/Syriaca?test_user_id=' + @creator_user.id.to_s, @place_file, "CONTENT_TYPE" => 'text/xml'
            submit_session.post 'dmm_api/create/item/Syriaca?test_user_id=' + @creator_user.id.to_s, @place_file, "CONTENT_TYPE" => 'text/xml'
            Rails.logger.debug "--flash is: " + submit_session.flash.inspect
            @publication = @creator_user.publications.first
            @publication.log_info
          end

          Rails.logger.debug "---Publication Created---"
          Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

          @publication.identifiers.each do |pi|
            Rails.logger.debug "-identifier-"
            Rails.logger.debug "title is: " +  pi.title
            Rails.logger.debug "was it modified?: " + pi.modified?.to_s
            assert_equal "Beth Agre", pi.title
          end


          # set the community
          #open_session do |update_session|
          #  update_session.put "api/v1/publications/#{@publication.id.to_s}" + '?test_user_id=' + @creator_user.id.to_s,
          #    { :community_name => @test_agent_community.name }.to_json, "CONTENT_TYPE" => 'application/json'
          #end

          #submit to the community
          Rails.logger.debug "---Submit Publication---"
          open_session do |submit_session|
            submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, :submit_comment => "I made a new pub", :community => { :id => @test_agent_community.id.to_s }
            assert_equal "Publication submitted to #{@test_agent_community.friendly_name}.", submit_session.flash[:notice]
            Rails.logger.debug "--flash is: " + submit_session.flash.inspect
          end
          @publication.reload

          #now meta should have it
          assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

          Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name


          #board should have 1 publication
          board_publications = Publication.find(:all, :conditions => { :owner_id => @test_agent_board.id, :owner_type => "Board" } )
          assert_equal 1, board_publications.length, "Board does not have 1 publication but rather, " + board_publications.length.to_s + " publications"

          Rails.logger.debug "Community Board has publication"

          #get the board publication
          board_publication = board_publications.first

          #find syriaca identifier
          syriaca_identifier = board_publication.identifiers.first

          assert board_publication.user_can_assign?(@community_admin)

          # verify it doesn't appear on voting list for non-admins and that the user can't vote on it
          open_session do |unassigned_session|
            unassigned_session.get 'user/board_dashboard?board_id=' + @test_agent_board.id.to_s + '&test_user_id=' + @board_user.id.to_s
            unassigned_session.assert_select "div#voting-column" do
              unassigned_session.assert_select "a[href ^= /publications/#{board_publication.id.to_s}/]", false
            end
            # waiting list should also be empty for non-admins
            unassigned_session.assert_select "div#publication_list_holder_waiting", false

            unassigned_session.get "/publications/#{board_publication.id.to_s}/syriaca_identifiers/#{syriaca_identifier.id.to_s}/editxml" + '?test_user_id=' + @board_user.id.to_s
            unassigned_session.assert_select "#vote_submit", false

          end

          # verify it does appear on board view for admin and assign it
          open_session do |admin_session|
            admin_session.get 'user/board_dashboard?board_id=' + @test_agent_board.id.to_s + '&test_user_id=' + @community_admin.id.to_s
            admin_session.assert_select "div#voting-column" do
              admin_session.assert_select "a[href ^= /publications/#{board_publication.id.to_s}/]"
            end
            admin_session.post 'publications/assign/' + board_publication.id.to_s + '?test_user_id=' + @community_admin.id.to_s, \
              :assignment => { :publication_id => board_publication.id }, \
              :voters => [ @board_user.id.to_s ]
          end

          # verify it now appears on voting board view for assigned user
          open_session do |assigned_session|
            assigned_session.get 'user/board_dashboard?board_id=' + @test_agent_board.id.to_s + '&test_user_id=' + @board_user.id.to_s
            assigned_session.assert_select "div#voting-column" do
              assigned_session.assert_select "a[href ^= /publications/#{board_publication.id.to_s}/]"
            end
            assigned_session.get "/publications/#{board_publication.id.to_s}/syriaca_identifiers/#{syriaca_identifier.id.to_s}/editxml" + '?test_user_id=' + @board_user.id.to_s
            assigned_session.assert_select "#vote_submit"
          end


          assert_not_nil  syriaca_identifier, "Did not find the syriaca identifier"
          Rails.logger.debug "Found syriaca identifier, will vote on it"

          #vote on meta publication
          open_session do |meta_session|
            meta_session.post 'publications/vote/' + board_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
              :comment => { :comment => "I vote to agree meta is great", :user_id => @board_user.id, :publication_id => syriaca_identifier.publication.id, :identifier_id => syriaca_identifier.id, :reason => "vote" }, \
              :vote => { :publication_id => syriaca_identifier.publication.id.to_s, :identifier_id => syriaca_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @test_agent_board.id.to_s, :choice => "ok" }

            Rails.logger.debug "--flash is: " + meta_session.flash.inspect

          end

          #reload the publication to get the vote associations to go thru?
          board_publication.reload

          vote_str = "Votes on meta are: "
          board_publication.votes.each do |v|
            vote_str = vote_str + v.choice
          end
          Rails.logger.debug  vote_str

          assert_equal 1, board_publication.votes.length, "publication should have one vote"
          assert_equal 1, board_publication.children.length, "publication should have one child"

          #vote should have changed publication to approved and put to finalizer
          assert_equal "approved", board_publication.status, "publication not approved after vote"
          Rails.logger.debug "--publication approved"

          #now finalizer should have it
          board_final_publication = board_publication.find_finalizer_publication
          finalizer = board_publication.find_finalizer_user

          assert_equal board_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
          assert_equal @default_finalizer, finalizer, "Default finalizer was not assigned"
          Rails.logger.debug "---Meta Finalizer has publication"

          board_final_identifier = board_final_publication.identifiers.first

          #finalize the meta
          open_session do |meta_finalize_session|

            meta_finalize_session.post 'publications/' + board_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
              :comment => 'I agree is great and now it is final'

            Rails.logger.debug "--flash is: " + meta_finalize_session.flash.inspect
            Rails.logger.debug "----session data is: " + meta_finalize_session.session.to_hash.inspect
            Rails.logger.debug meta_finalize_session.body
          end

          board_final_publication.reload
          assert_equal "finalized", board_final_publication.status, "board final publication not finalized"
          
          # make sure the content was preprocessed
          # preprocessed version has a new name entry
          assert_match /name221-1c/, board_final_publication.identifiers.first.content
 

          Rails.logger.debug "committed"

          #compare the publications
          #you must look at the output to check the results of the comparisons
          #final and submitters' copy should have comments and votes
          Rails.logger.debug "++++++++USER PUBLICATION++++++"
          @creator_user.publications.first.log_info

          board_publication.reload
          Rails.logger.debug "++++++++meta BOARD PUBLICATION++++++"
          board_publication.log_info

          Rails.logger.debug "Compare user with meta finalizer publication"
          compare_publications(@creator_user.publications.first, board_final_publication)
          @publication.destroy

          Rails.logger.debug "ENDED TEST: user creates and submits publication to syriaca community"
        end

        should "user creates and submits publication with person record to community"  do
          Rails.logger.debug "BEGIN TEST: user creates and submits publication with person record to community"

          assert_not_equal nil, @test_person_community, "Community not created"

          #create a publication with a session
          Rails.logger.debug "---Create A New Publication---"
          open_session do |submit_session|
            #submit_session.post 'api/v1/xmlitems/Syriaca?test_user_id=' + @creator_user.id.to_s, @place_file, "CONTENT_TYPE" => 'text/xml'
            submit_session.post 'dmm_api/create/item/SyriacaPerson?test_user_id=' + @creator_user.id.to_s, @person_file, "CONTENT_TYPE" => 'text/xml'
            Rails.logger.debug "--flash is: " + submit_session.flash.inspect
            @publication = @creator_user.publications.first
            @publication.log_info
          end

          Rails.logger.debug "---Publication Created---"
          Rails.logger.debug "---Identifiers for publication " + @publication.title + " are:"

          @publication.identifiers.each do |pi|
            Rails.logger.debug "-identifier-"
            Rails.logger.debug "title is: " +  pi.title
            Rails.logger.debug "was it modified?: " + pi.modified?.to_s
            assert_equal "ʿAbd al-Masih b. Naʿima of Homs — ", pi.title
          end

          # set the community
          #open_session do |update_session|
          #  update_session.put "api/v1/publications/#{@publication.id.to_s}" + '?test_user_id=' + @creator_user.id.to_s,
          #    { :community_name => @test_agent_community.name }.to_json, "CONTENT_TYPE" => 'application/json'
          #end

          #submit to the community
          Rails.logger.debug "---Submit Publication---"
          open_session do |submit_session|
            submit_session.post 'publications/' + @publication.id.to_s + '/submit/?test_user_id=' + @creator_user.id.to_s, :submit_comment => "I made a new pub", :community => { :id => @test_person_community.id.to_s }
            assert_equal "Publication submitted to #{@test_person_community.friendly_name}.", submit_session.flash[:notice]
            Rails.logger.debug "--flash is: " + submit_session.flash.inspect
          end
          @publication.reload

          #now meta should have it
          assert_equal "submitted", @publication.status, "Publication status not submitted " + @publication.community_id.to_s + " id "

          Rails.logger.debug "---Publication Submitted to Community: " + @publication.community.name

          #disperse board should have 1 publication
          board_publications = Publication.find(:all, :conditions => { :owner_id => @test_disperse_board.id, :owner_type => "Board" } )
          assert_equal 1, board_publications.length, "Disperse Board does not have 1 publication but rather, " + board_publications.length.to_s + " publications"
          board_publication = board_publications.first
          syriaca_person_identifier = board_publication.identifiers.first
          open_session do |disperse_session|
            disperse_session.post 'publications/vote/' + board_publication.id.to_s + '?test_user_id=' + @disperser_user.id.to_s, \
              :comment => { :comment => "I vote to agree meta is great", :user_id => @board_user.id, :publication_id => syriaca_person_identifier.publication.id, :identifier_id => syriaca_person_identifier.id, :reason => "vote" }, \
              :vote => { :publication_id => syriaca_person_identifier.publication.id.to_s, :identifier_id => syriaca_person_identifier.id.to_s, :user_id => @disperser_user.id.to_s, :board_id => @test_disperse_board.id.to_s, :choice => "ok" }
          end
          

          #should have skipped finalization and next board should have 1 publication
          board_publications = Publication.find(:all, :conditions => { :owner_id => @test_person_board.id, :owner_type => "Board" } )
          assert_equal 1, board_publications.length, "Board does not have 1 publication but rather, " + board_publications.length.to_s + " publications"

          Rails.logger.debug "Community Board has publication"

          #get the board publication
          board_publication = board_publications.first

          # make sure the dispersed board is found in previous parents
          assert_equal [@test_disperse_board], board_publication.find_previous_boards

          #find syriaca identifier
          syriaca_person_identifier = board_publication.identifiers.first

          assert board_publication.user_can_assign?(@community_admin)

          # verify it doesn't appear on voting list for non-admins and that the user can't vote on it
          open_session do |unassigned_session|
            unassigned_session.get 'user/board_dashboard?board_id=' + @test_person_board.id.to_s + '&test_user_id=' + @board_user.id.to_s
            unassigned_session.assert_select "div#voting-column" do
              unassigned_session.assert_select "a[href ^= /publications/#{board_publication.id.to_s}/]", false
            end
            # waiting list should also be empty for non-admins
            unassigned_session.assert_select "div#publication_list_holder_waiting", false

            unassigned_session.get "/publications/#{board_publication.id.to_s}/syriaca_person_identifiers/#{syriaca_person_identifier.id.to_s}/editxml" + '?test_user_id=' + @board_user.id.to_s
            unassigned_session.assert_select "#vote_submit", false

          end

          # verify it does appear on board view for admin and assign it
          open_session do |admin_session|
            admin_session.get 'user/board_dashboard?board_id=' + @test_person_board.id.to_s + '&test_user_id=' + @community_admin.id.to_s
            admin_session.assert_select "div#voting-column" do
              admin_session.assert_select "a[href ^= /publications/#{board_publication.id.to_s}/]"
            end
            admin_session.post 'publications/assign/' + board_publication.id.to_s + '?test_user_id=' + @community_admin.id.to_s, \
              :assignment => { :publication_id => board_publication.id }, \
              :voters => [ @board_user.id.to_s ]
          end

          # verify it now appears on voting board view for assigned user
          open_session do |assigned_session|
            assigned_session.get 'user/board_dashboard?board_id=' + @test_person_board.id.to_s + '&test_user_id=' + @board_user.id.to_s
            assigned_session.assert_select "div#voting-column" do
              assigned_session.assert_select "a[href ^= /publications/#{board_publication.id.to_s}/]"
            end
            assigned_session.get "/publications/#{board_publication.id.to_s}/syriaca_person_identifiers/#{syriaca_person_identifier.id.to_s}/editxml" + '?test_user_id=' + @board_user.id.to_s
            assigned_session.assert_select "#vote_submit"
          end


          assert_not_nil  syriaca_person_identifier, "Did not find the syriaca identifier"
          Rails.logger.debug "Found syriaca identifier, will vote on it"

          #vote on meta publication
          open_session do |meta_session|
            meta_session.post 'publications/vote/' + board_publication.id.to_s + '?test_user_id=' + @board_user.id.to_s, \
              :comment => { :comment => "I vote to agree meta is great", :user_id => @board_user.id, :publication_id => syriaca_person_identifier.publication.id, :identifier_id => syriaca_person_identifier.id, :reason => "vote" }, \
              :vote => { :publication_id => syriaca_person_identifier.publication.id.to_s, :identifier_id => syriaca_person_identifier.id.to_s, :user_id => @board_user.id.to_s, :board_id => @test_person_board.id.to_s, :choice => "ok" }

            Rails.logger.debug "--flash is: " + meta_session.flash.inspect

          end

          #reload the publication to get the vote associations to go thru?
          board_publication.reload

          vote_str = "Votes on meta are: "
          board_publication.votes.each do |v|
            vote_str = vote_str + v.choice
          end
          Rails.logger.debug  vote_str

          assert_equal 1, board_publication.votes.length, "publication should have one vote"
          assert_equal 1, board_publication.children.length, "publication should have one child"

          #vote should have changed publication to approved and put to finalizer
          assert_equal "approved", board_publication.status, "publication not approved after vote"
          Rails.logger.debug "--publication approved"

          #now finalizer should have it
          board_final_publication = board_publication.find_finalizer_publication

          assert_equal board_final_publication.status, "finalizing", "Board user's publication is not for finalizing"
          Rails.logger.debug "---Meta Finalizer has publication"

          board_final_identifier = board_final_publication.identifiers.first

          #finalize the meta
          open_session do |meta_finalize_session|

            meta_finalize_session.post 'publications/' + board_final_publication.id.to_s + '/finalize/?test_user_id=' + @board_user.id.to_s, \
              :comment => 'I agree is great and now it is final'

            Rails.logger.debug "--flash is: " + meta_finalize_session.flash.inspect
            Rails.logger.debug "----session data is: " + meta_finalize_session.session.to_hash.inspect
            Rails.logger.debug meta_finalize_session.body
          end

          board_final_publication.reload
          assert_equal "finalized", board_final_publication.status, "board final publication not finalized"

          Rails.logger.debug "committed"

          #compare the publications
          #you must look at the output to check the results of the comparisons
          #final and submitters' copy should have comments and votes
          Rails.logger.debug "++++++++USER PUBLICATION++++++"
          @creator_user.publications.first.log_info

          board_publication.reload
          Rails.logger.debug "++++++++meta BOARD PUBLICATION++++++"
          board_publication.log_info

          Rails.logger.debug "Compare user with meta finalizer publication"
          compare_publications(@creator_user.publications.first, board_final_publication)
          @publication.destroy

          Rails.logger.debug "ENDED TEST: user creates and submits publication to syriaca community"
        end
      end
    end
  end
end
