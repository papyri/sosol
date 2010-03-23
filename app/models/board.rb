#Board represents an editorial review board.
class Board < ActiveRecord::Base
  has_many :decrees, :dependent => :destroy
  has_many :emailers, :dependent => :destroy
  
  has_many :votes
  
  has_and_belongs_to_many :users
  belongs_to :finalizer_user, :class_name => 'User'
  
  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner
  
  # :identifier_classes is an array of identifier classes this board has
  # commit control over. This isn't done relationally because it's not a
  # relation to instances of identifiers but rather to identifier classes
  # themselves.
  serialize :identifier_classes
  
  validates_uniqueness_of :title, :case_sensitive => false
  validates_presence_of :title
  
  has_repository
  
  # workaround repository need for owner name for now
  def name
    return title
  end
  
  def human_name
    return title
  end
  
  def after_create
    repository.create
  end
  
  def before_destroy
    repository.destroy
  end
  
  def result_actions
    #return array of possible actions that can be implemented
    retval = []
    identifier_classes.each do |ic|
      im = ic.constantize.instance_methods
      match_expression = /(result_action_)/
      im.each do |method_name|
        if method_name =~ /(result_action_)/
          retval << method_name.sub(/(result_action_)/, "")
        end
      end
    end
    retval
    
  end
  
  def result_actions_hash  
    ra = result_actions    
    ret_hash = {}
    
    #create hash
    ra.each do |v|
      ret_hash[v.sub(/_/, " ").capitalize] = v
    end
    ret_hash
  end

  def controls_identifier?(identifier)
   self.identifier_classes.include?(identifier.class.to_s)  
  end



  #Tallies the votes and returns the resulting decree action or returns an empty string if no decree has been triggered.
  def tally_votes(votes)
    # NOTE: assumes board controls one identifier type, and user hasn't made
    # rules where multiple decrees can be true at once
    
    self.decrees.each do |decree|
      if decree.perform_action?(votes)
        return decree.action
      end
    end
    
    return ""
  end #tally_votes
  

  def send_status_emails(when_to_send, publication)

  	#search emailer for status
  	if self.emailers == nil
  	  return
  	end
    
    #find identifiers for email
    email_identifiers = Array.new
    publication.identifiers.each do |identifier|
      if self.identifier_classes.include?(identifier.class.to_s)
        email_identifiers << identifier      
      end
    end
    
    
  	self.emailers.each do |mailer|
  	
  		if mailer.when_to_send == when_to_send
  			#send the email
  			addresses = Array.new	
  			#--addresses
  			
        #board members
        if mailer.send_to_all_board_members
          self.users.each do |board_user|          
            addresses << board_user.email        
          end
        end
        
        #other sosol users
        if mailer.users
          mailer.users.each do |user|
            if user.email != nil
              addresses << user.email
            end
          end
        end
        
        #extra addresses
        if mailer.extra_addresses
          extras = mailer.extra_addresses.split(" ")
          extras.each do |extra|
            addresses << extra
          end
        end
        
        #owner address
  			if mailer.send_to_owner
  				if publication && publication.creator && publication.creator.email
  					addresses << publication.creator.email
  				end
  			end
  			
  			#--document content
  			if mailer.include_document
  				#document_content = self.content 
          document_content = ""
          email_identifiers.each do |ec|
            document_content += ec.content
          end
  			else
  				document_content = nil
  			end
  			
  			body = mailer.message
  			
  			#TODO parse the message to add local vars
  			#votes
  			#comments        
        if mailer.include_comments  
          comment_text = ""       
          begin
            comments = Comment.find_all_by_publication_id(publication.origin.id)    
          rescue
            #do nothing no comments found
          end                        
            if comments
              comments.each do |comment|
                if comment.comment
                  comment_text += comment.comment 
                end
                comment_text += "("
                if comment.reason
                  comment_text += comment.reason 
                end
                if comment.identifier
                  comment_text += " on " + comment.identifier.class::FRIENDLY_NAME
                end
                if comment.user && comment.user.name
                  comment_text += " by " + comment.user.name 
                end
                comment_text += " " + comment.created_at.to_formatted_s(:db)
                comment_text += ")"
                comment_text += "\n"
              end            
              body += "\n"
              body += "Comments:\n"
              body += comment_text
            end          
        end
  			#owner
  			#status
        friendly_name = ""
        email_identifiers.each do |ec|
          friendly_name += ec.class::FRIENDLY_NAME
        end
        
  			#subject_line = publication.title + " " + self.class::FRIENDLY_NAME + "-" + publication.status
        subject_line = publication.title + " " + friendly_name + "-" + when_to_send
  			#if addresses == nil 
  			#raise addresses.to_s + addresses.size.to_s
  			#else
  				#EmailerMailer.deliver_boardmail(addresses, subject_line, body, epidoc)   										
  			#end
  			
  			addresses.each do |address|
  				if address && address.strip != ""
  					EmailerMailer.deliver_boardmail(address, subject_line, body, document_content)   										
  				end
  			end
  			
  		end
  	end	
  	
  end


  
  
  
  
end
