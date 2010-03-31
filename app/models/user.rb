class User < ActiveRecord::Base
  validates_uniqueness_of :name, :case_sensitive => false
  
  has_many :user_identifiers, :dependent => :destroy
  
  has_and_belongs_to_many :boards
  has_many :finalizing_boards, :class_name => 'Board', :foreign_key => 'finalizer_user_id'
  
  has_and_belongs_to_many :emailers
  
  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner, :dependent => :destroy
  
  has_many :comments
  
  has_repository
  
  def after_create
    repository.create
    
    # create some fixture publications/identifiers
    # ["p.genova/p.genova.2/p.genova.2.67.xml",
    # "sb/sb.24/sb.24.16003.xml",
    # "p.lond/p.lond.7/p.lond.7.2067.xml",
    # "p.ifao/p.ifao.2/p.ifao.2.31.xml",
    # "p.gen.2/p.gen.2.1/p.gen.2.1.4.xml",
    # "p.harr/p.harr.1/p.harr.1.109.xml",
    # "p.petr.2/p.petr.2.30.xml",
    # "sb/sb.16/sb.16.12255.xml",
    # "p.harr/p.harr.2/p.harr.2.193.xml",
    # "p.oxy/p.oxy.43/p.oxy.43.3118.xml",
    # "chr.mitt/chr.mitt.12.xml",
    # "sb/sb.12/sb.12.11001.xml",
    # "p.stras/p.stras.9/p.stras.9.816.xml",
    # "sb/sb.6/sb.6.9108.xml",
    # "p.yale/p.yale.1/p.yale.1.43.xml",

    if ENV['RAILS_ENV'] != 'test'
      if ENV['RAILS_ENV'] == 'development'
        self.admin = true
        self.save!
      
        ['papyri.info/ddbdp/p.genova;2;67',
         'papyri.info/ddbdp/sb;24;16003',
         'papyri.info/ddbdp/p.lond;7;2067',
         'papyri.info/ddbdp/p.harr;1;109',
         'papyri.info/ddbdp/p.yale;1;44',
         'papyri.info/ddbdp/p.tebt;2;414'
        ].each do |pn_id|
          p = Publication.new
          p.populate_identifiers_from_identifiers(pn_id)
          p.owner = self
          p.creator = self
          p.save!
          p.branch_from_master
              
          e = Event.new
          e.category = "started editing"
          e.target = p
          e.owner = self
          e.save!
        end # each
      end # == development
    end # != test
  end # after_create
  
  def human_name
    # get user name
    if self.full_name && self.full_name.strip != ""
      return self.full_name.strip
    else
      return who_name = self.name
    end
  end
  
  def grit_actor
    Grit::Actor.new(self.full_name, self.email)
  end
  
  def author_string
    "#{self.full_name} <#{self.email}>"
  end
  
  def git_author_string
    local_time = Time.now
    "#{self.author_string} #{local_time.to_i} #{local_time.strftime('%z')}"
  end
  
  def before_destroy
    repository.destroy
  end
end
