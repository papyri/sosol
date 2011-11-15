class EmailerMailer < ActionMailer::Base
    
  def send_email_out(addresses, subject_line, body_content, article_content=nil)
              
    #TODO check that email is creatible, ie has valid addresses
    
    from "SoSOL"
    sent_on Time.now
  
    subject subject_line
    recipients  addresses
    #cc = 
    #bcc = addresses
    
    if article_content != nil
      attachment :content_type => "text/plain", :body => article_content
    end   
    
    body body_content
  
  end
  
  
  def send_withdraw_note(addresses, publication_title) 
    #send note to publication creator that the pub has been withdrawn
    #they can checkout the comments to see if there is more info about the withdraw
    from "SoSOL"
    sent_on Time.now
    
    subject publication_title + " has been withdrawn."
    recipients addresses
    
    body publication_title + " has been withdrawn from editorial review.  If you did not request this withdrawl, please check the publication's comments for more information. This may also represent downstream error. Please resubmit."
    
  end
  
end
