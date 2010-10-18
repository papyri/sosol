class EmailerMailer < ActionMailer::Base
    
  def boardmail(addresses, subject_line, body_content, article_content)
              
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
  
  def maileverybody(fromaddress, toaddress, subject_line, email_content)
              
    #TODO check that email is creatible, ie has valid addresses
    
    sent_on Time.now
    from "SoSOL"
    #if fromaddress.blank?
    #  from "SoSOLAdmin"
    #else
    #  from "SoSOLAdmin." + fromaddress.slice(/[\w._]+@/).chop
    #end
    recipients toaddress
    subject subject_line
    body email_content
    
  end

end
