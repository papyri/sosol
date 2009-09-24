class User < ActiveRecord::Base
  validates_uniqueness_of :name, :case_sensitive => false
  
  has_and_belongs_to_many :boards
  
  has_and_belongs_to_many :emailers
  
  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner, :dependent => :destroy
  
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
      ['oai:papyri.info:identifiers:ddbdp:0118:2:67',
       'oai:papyri.info:identifiers:ddbdp:0239:24:16003',
       'oai:papyri.info:identifiers:ddbdp:0154:7:2067',
       'oai:papyri.info:identifiers:ddbdp:0129:1:109',
       'oai:papyri.info:identifiers:ddbdp:0228:1:44',
       'oai:papyri.info:identifiers:ddbdp:0206:2:414'
      ].each do |pn_id|
        p = Publication.new
        p.populate_identifiers_from_identifier(pn_id)
        p.owner = self
        p.save!
        p.branch_from_master
      
        e = Event.new
        e.category = "started editing"
        e.target = p
        e.owner = self
        e.save!
      end
    end
  end
  
  def before_destroy
    repository.destroy
  end
end
