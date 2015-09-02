class EmailerMailer < ActionMailer::Base
  default from: "#{ Sosol::Application.config.site_email_from || Sosol::Application.config.site_name}"

  #Basic Email
  #*Args:*
  #- +addresses+ an array of email addresses
  #- +subject_line+ string for subject line
  #- +body_content+ string for content of email
  #- +article_content+ text to be attached to email
  def general_email(addresses, subject_line, body_content, article_content=nil)
              
    if article_content != nil
      attachments.inline['attachment.txt'] = article_content
    end   
 
    @content = body_content
    
    #TODO check that email is creatible, ie has valid addresses
    mail(:to => addresses, :subject => subject_line)
    
  end

  # Email indicating a publication has been withdrawn
  #*Args*
  #- +addresses+ an array of email addresses
  #- +publication_title+ title of the publication that has been withdrawn
  def withdraw_note(addresses, publication_title) 
    #send note to publication creator that the pub has been withdrawn
    #they can checkout the comments to see if there is more info about the withdraw
   
    @publication_title= publication_title 

    mail(:to => addresses, :subject => publication_title + " has been withdrawn.")
    
  end
  
end
