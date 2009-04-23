class Article < ActiveRecord::Base
  include ArticlesHelper
  
  has_many :comments
  has_many :votes
  belongs_to :user
  belongs_to :master_article
  belongs_to :board
  
  #article types
  has_one :meta
  has_one :transcription
  has_one :translation
   
  # has_many :events
  validates_presence_of :content
  
  # validate :must_be_valid_xml
  # validate :must_be_valid_epidoc
  
  #article has serveral status states
  #new - user created ie does not exist elsewhere
  #edit - editing existing ie alread is in repository somewhere
  #submitted - user submitted and it is being reviewed by the board
  #accepted - board has approved
  #rejected - board rejected
  #graffiti - board hated it  
  
#edit_article_path(article)


#Returns the object represented by the article's category
  def get_category_obj()
    if self.meta
      obj = self.meta
    elsif self.transcription
      obj = self.transcription
    elsif self.translation
      obj = self.translation           
    else
      obj = nil 
    end
    
    obj   
  end
  

  
  def must_be_valid_xml
    # errors.add_to_base("Content must be valid XML") unless (valid_xml?(content) != nil)
  end

  def must_be_valid_epidoc
    errors.add_to_base("Content must be valid EpiDoc") unless valid_epidoc?(content)
  end
  
  
  
  
  
  #Check with the board to see if we want to send an email on status change.
  def send_status_emails(when_to_send)
 		#errMsg = " " 
  	#search emailer for status
  	self.board.emailers.each do |mailer|
  	
#  		doSend = false
#  		if when_to_send != nil
#  			doSend = mailer.when == self.status
#  		else
#  			doSend = mailer.when == self.status
#  		end
  		
  		if mailer.when == when_to_send
  			#send the email
  			addresses = Array.new	
  			#--addresses
  			mailer.users.each do |user|
  				if user.email != nil
  					addresses << user.email
  				end
  			end
  			extras = mailer.extra_addresses.split(" ")
  			extras.each do |extra|
  				addresses << extra
  			end
  			if mailer.send_to_owner
  				if self.user.email != nil
  					addresses << self.user.email
  				end
  			end
  			
  			#--epidoc
  			if mailer.include_document
  				epidoc = self.get_category_obj().get_content #xml content or such... how to get??
  			else
  				epidoc = nil
  			end
  			
  			body = mailer.message
  			
  			#TODO parse the message to add local vars
  			#votes
  			
  			#comments
  			#owner
  			#status
  			#who changed status
  			subject_line = self.master_article.title + " " + self.category + "-" + self.status
  			#if addresses == nil 
  			#raise addresses.to_s + addresses.size.to_s
  			#else
  				EmailerMailer.deliver_boardmail(addresses, subject_line, body, epidoc)   										
  			#end
  			
  		end
  	end	
  	
  end
  
  
  
  
  
  
  
  
  
  
end
