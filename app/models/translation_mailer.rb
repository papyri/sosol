class TranslationMailer < ActionMailer::Base
  
	def final_translation(user_email, epidoc)

		recipients user_email
		from "SoSOL"
		subject "Translation Final"
		sent_on Time.now

		attachment :content_type => "text/plain", :body => epidoc

	end


end
