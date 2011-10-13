class Comment < ActiveRecord::Base
  # belongs_to :article
  belongs_to :user
  belongs_to :publication
  belongs_to :identifier
  
  #create named scope for each type of reason
  named_scope :finalizing, :conditions => { :reason => 'finalizing' }
  named_scope :submit, :conditions => { :reason => 'submit' }
  named_scope :general, :conditions => { :reason => 'general' }
  named_scope :vote, :conditions => { :reason => 'vote' }

  def comment=(comment_text)
    write_attribute(:comment, CGI.escape(comment_text))
  end

  def comment
    CGI.unescape(read_attribute(:comment) || '')
  end
  
  class CombineComment
    attr_accessor :xmltype, :who, :when, :why, :comment 
    
    def initialize
      @xmltype = ''
      @who = ''
      @when = ''
      @why = ''
      @comment = ''
    end
    
  end
  
end
