class User < ActiveRecord::Base
  validates_uniqueness_of :name
  has_many :articles
  has_many :comments
  has_many :publications
  
  def repository
    @repository ||= Repository.new(self)
  end
  
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
    
    [['P.Genova II 67','oai:papyri.info:identifiers:ddbdp:0118:2:67','hgv30114'],
     ['SB XXIV 16003','oai:papyri.info:identifiers:ddbdp:0239:24:16003','hgv79280'],
     ['P.Lond. VII 2067','oai:papyri.info:identifiers:ddbdp:0154:7:2067','hgv1628'],
     ['P.Harr. I 109','oai:papyri.info:identifiers:ddbdp:0129:1:109','hgv31474']
    ].each do |fixture|
      pubtitle = fixture[0]
      pubid = fixture[1]
      hgvid = fixture[2]
      
      p = Publication.new
      
      i = DDBIdentifier.new
      i.name = pubid
      
      h = HGVMetaIdentifier.new
      h.name = hgvid
      
      p.title = pubtitle
      p.identifiers << i
      p.identifiers << h
      
      self.publications << p
    end
    
    # try populating from ids
    p = Publication.new
    # "p.yale/p.yale.1/p.yale.1.44.xml"
    p.populate_identifiers_from_identifier(
      'oai:papyri.info:identifiers:ddbdp:0228:1:44')
    self.publications << p
    
  end
  
  def before_destroy
    repository.destroy
    publications.destroy_all
  end
end
