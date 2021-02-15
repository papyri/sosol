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
  scope :commit, -> { where(reason: 'commit') }
  scope :finalizing, -> { where(reason: 'finalizing') }
  scope :submit, -> { where(reason: 'submit') }
  scope :general, -> { where(reason: 'general') }
  scope :vote, -> { where(reason: 'vote') }

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
