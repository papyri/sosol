class TranslationMailer < ActionMailer::Base
  
def final_translation(user_email)

recipients user_email
from "SoSOL"
subject "Translation Final"
sent_on Time.now
body { }


end

end
