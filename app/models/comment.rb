#Comment represents a comment made on an identifier/publication.
#Standard reasons for a comment are:
#- *commit* when an identifier is commited
#- *submit* when a publication is submitted
#- *vote* when a vote is cast
#- *finalizing* when a publication is finalized
#- *general* other cases, such as an opinion comment on someone else's publication
class Comment < ActiveRecord::Base
  # belongs_to :article
  belongs_to :user
  belongs_to :publication
  belongs_to :identifier
  
  #create named scope for each type of reason
  named_scope :commit, :conditions => { :reason => 'commit' }
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

  # Get an api exposable version of the comment
  def api_get()
    return { 
        :comment_id => self.id, 
        :user => self.user.human_name, 
        :reason => self.reason, 
        :created_at => self.created_at,
        :updated_at => self.updated_at,
        :comment => self.comment
    }
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
