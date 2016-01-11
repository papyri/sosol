# a Pass Through community is one which funnels publications
# to another community or an external agent upon completion
class PassThroughCommunity < Community

  validate :pass_to_must_be_valid

  def pass_to_must_be_valid
    # must  be a valid object and not itself
    if self.pass_to == self.name || pass_to_obj.nil?
      errors.add(:pass_to, "Must be a valid Community Name or Agent URI")
    end
  end

  def pass_to_obj
    if self.pass_to.nil?
      return nil  
    end
    # it's either a community or an external agent
    Community.find_by_name(self.pass_to) || AgentHelper::agent_of(self.pass_to)
  end

  #Checks to see whether or not to allow members to submit to the community
  # Overrides the base class method to require an end_user
  #
  #*Returns*
  #- true if the community is setup properly to receive submissions
  #- false if community should not be submitted to
  def is_submittable?
    #if there is nowhere for the final publication to go, don't let them submit
    #if there are no boards to review the publication, don't let them submit
    return !self.pass_to_obj.nil? && (self.boards && self.boards.length > 0)
  end

  # Promotes a publication to the next step in the workflow
  # after board approval.
  #
  # For a PassThrough community this means it either
  # gets submitted to the next community or sent off
  # to an agent
  # 
  # *Args* +publication+ the publication to promote
  #
  def promote(publication)
    #copy to  space
    Rails.logger.debug "----pass through to get it"
    next_obj = self.pass_to_obj
    Rails.logger.debug "---" + next_obj

    if next_obj.class.name =~ /Community/
      community_copy = publication.copy_to_owner(next_obj, "#{self.name}/#{publication.creator.name}/#{publication.title}") #adding orginal creator to title for next community
      community_copy.status = "editing"
      community_copy.identifiers.each do |id|
        id.status = "editing"
        id.save
      end
      #disconnect the parent/origin connections
      community_copy.parent = nil

      #remove the original creator id (that info is now in the git history )
      community_copy.creator_id = community_copy.owner_id
      community_copy.save!

    elsif next_obj.class.name =~ /Agent/
      begin
        agent_client = AgentHelper::get_client(next_obj)
        if agent_client.nil?
          raise Exception.new("Unable to get client for #{next_obj.inspect}")
        end
        self.identifiers.each do |id|
          transformation = agent[:transformations][id.class.name]
          unless transformation.nil?
            signed_off_messages = []
            # TODO reviwed_by ... how to pass
            reviewed_by.each do |m|
              signed_off_messages << m
            end
            content = JRubyXML.apply_xsl_transform(
              JRubyXML.stream_from_string(id.content),
              JRubyXML.stream_from_file(File.join(Rails.root, transform)),
             'urn' => id.urn_attribute, # TODO not urn attribute ... something more general
             'reviewers' => signed_off_messages.join(',')
            )
          end
          agent_client.post_content(content)
          # we want to return false here because the identifier itself
          # wasn't modified
        end
      rescue Exception => e
        Rails.logger.error(e) 
        Rails.logger.error(e.backtrace) 
        raise "Unable to send finalization copy to agent #{agent.inspect}"
      end
    else
      raise Exeption.new("Unknown pass_to type #{next_obj}")
    end

    # the original publication is done now so we can
    # set the status of the original publication
    # to committed
    publication.origin.change_status("committed")
  end

  def finalize(publication)
    if self.pass_to_obj.nil?
      raise "No pass through point for the community. Unable to finalize"
    end
  end

end
