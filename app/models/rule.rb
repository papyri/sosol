class Rule < ActiveRecord::Base
  attr_accessible :expire_days, :floor
  belongs_to :decree

  def apply_rule?(votes)
    last_date = nil
    votes.each do |v|
      if last_date.nil? || votes.updated_at > last_date
        last_date = votes.updated_at
      end
    end
    now = DateTime.now()
    return (now >= votes.updated_at + self.expire_days.days) && self.decree.perform_action?(votes,self.floor)
  end

end
