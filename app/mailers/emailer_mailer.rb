class EmailerMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
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

  # Multipurpose email whose subject is one or more identifiers in publication
  #*Args*
  #- +topic+ the topic or reason for the message
  #- +identifiers+ the (possibly subset) of identifiers from a publication which are 
  #                the subject of the mail
  #- +board_publication+ the publication currently owned by the board that initiated the mail
  #- +recipients+ an array of email addresses
  #- +attach_content+ boolean to indicate whether identifier content should be included
  #                    as an attachment
  #- +include_comments+ boolean to indicate whether identifier comments should be included
  #                    in the mail content
  #- +message_content+ message contents will be set to this. Can include one or more of
  #                    any of the following variables which will be parsed and replaced 
  #                    !IDENTIFIER_TITLES !IDENTIFIER_LINKS !PUBLICATION_TITLE !PUBLICATION_LINK
  #                    !PUBLICATION_CREATOR_NAME !BOARD_PUBLICATION_LINK !BOARD_OWNER
  #- +message_subject+  (optional) if not nil, will override the default system-generated subject
  #                    any of the following variables will be parsed and replaced 
  #                    !IDENTIFIER_TITLES !PUBLICATION_TITLE !TOPIC
  def identifier_email(topic,identifiers,board_publication,receipients,attach_content,include_comments,message_content,message_subject=nil)
    # add attachments
    if (identifiers.length > 0 && attach_content)
      document_content = ""
      identifiers.each do |ec|
        unless ec.nil?
          document_content += Identifier.find(ec[:id]).content || ""
        end
      end
      attachments.inline['attachment.txt'] = document_content
    end
    if include_comments  
      @comments = Comment.find_all_by_publication_id(identifiers[0].publication.origin.id)    
    else
      @comments = [] 
    end

    na_text = I18n.t("mailers.notapplicable")
    @identifier_links = identifiers.length > 0 ? Hash[identifiers.map {|x| [x.title, preview_url(x)]}] : Hash[ na_text, dashboard_url ]

    # publication title and publication link should always give us the publication of origin
    @publication_links = identifiers.length > 0 ? Hash[identifiers.first.publication.origin.title, url_for(identifiers.first.publication.origin)] : Hash[ na_text, dashboard_url ]

    @board_publication_links = board_publication.nil? ? Hash[ na_text, dashboard_url ] : Hash[ board_publication.title , url_for(board_publication) ]

    if board_publication.nil?
      board_owner = na_text
    else
      board_owner = board_publication.owner.friendly_name
    end

    # we want to leave it to mailer view to be able to relace the IDENTIFIER_LINK and PUBLICATION_LINK placeholders with active links
    # to the identifiers and publications but first we need to do some weird string wrangling here to make sure that the user-entered 
    # email message escapes any unsafe content 
    # (see http://makandracards.com/makandra/2579-everything-you-know-about-html_safe-is-wrong for explaination)
    @message = "".html_safe 
    @message <<  message_content.gsub(/!IDENTIFIER_TITLES/,identifiers.collect{|ei| ei.title}.join('; ')).gsub(/!PUBLICATION_TITLE/,identifiers[0].publication.origin.title).gsub(/!TOPIC/,topic) 
                 .gsub(/!PUBLICATION_CREATOR_NAME/,identifiers[0].publication.origin.creator.full_name).gsub(/!BOARD_OWNER/,board_owner)


    identifier_titles = identifiers.collect{|ei| ei.title}.join('; ')
    if message_subject.nil? || message_subject == ''
      message_subject = topic + ': ' + identifiers[0].publication.origin.title + " " + identifier_titles
    else
      message_subject = message_subject.gsub(/!TOPIC/,topic).gsub(/!PUBLICATION_TITLE/,identifiers[0].publication.origin.title).gsub(/!IDENTIFIER_TITLES/,identifier_titles)
    end
    # make sure we have a decent length for the subject
    message_subject = truncate(message_subject, length:75)
    mail(:to => receipients, :subject => message_subject)
  end

  protected
    def preview_url(identifier)
      polymorphic_url([identifier.publication,identifier],:action => :preview)
    end
end
