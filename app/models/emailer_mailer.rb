class EmailerMailer < ActionMailer::Base
		
		
	def boardmail(addresses, subject_line, body_content, article_content)
							
		#TODO check that email is creatible, ie has valid addresses
		#raise addresses
		from "SoSOL"
		sent_on Time.now
	
		subject subject_line
		recipients  addresses
		#cc = 
		#bcc = 
				
		
		if article_content != nil
			attachment :content_type => "text/plain", :body => article_content
		end		
		
		body body_content
	
	end

end
