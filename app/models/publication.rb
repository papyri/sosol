class Publication < ActiveRecord::Base
  include NumbersRDF::NumbersHelper
  
  validates_presence_of :title, :branch
  
  belongs_to :owner, :polymorphic => true
  has_many :identifiers
  has_many :events, :as => :target
  
  validates_uniqueness_of :title, :scope => 'owner_id'
  validates_uniqueness_of :branch, :scope => 'owner_id'

  validates_each :branch do |model, attr, value|
    # Excerpted from git/refs.c:
    # Make sure "ref" is something reasonable to have under ".git/refs/";
    # We do not like it if:
    if value =~ /^\./ ||    # - any path component of it begins with ".", or
       value =~ /\.\./ ||   # - it has double dots "..", or
       value =~ /[~^: ]/ || # - it has [..], "~", "^", ":" or SP, anywhere, or
       value =~ /\/$/ ||    # - it ends with a "/".
       value =~ /\.lock$/   # - it ends with ".lock"
      model.errors.add(attr, "Branch \"#{value}\" contains illegal characters")
    end
    # not yet handling ASCII control characters
  end
  
  def populate_identifiers_from_identifier(identifier)
    self.title = identifier.tr(':','_')
    # Coming in from an identifier, build up a publication
    identifiers = identifiers_to_hash(identifier_to_identifiers(identifier))
    if identifiers.has_key?('ddbdp')
      identifiers['ddbdp'].each do |ddb|
        d = DDBIdentifier.new(:name => ddb)
        self.identifiers << d
        self.title = d.titleize
      end
    end
    
    # Use HGV hack for now
    if identifiers.has_key?('hgv') && identifiers.has_key?('trismegistos')
      identifiers['trismegistos'].each do |tm|
        tm_nr = identifier_to_components(tm).last
        self.identifiers << HGVMetaIdentifier.new(
          :name => "#{identifiers['hgv'].first}",
          :alternate_name => "hgv#{tm_nr}")
      end
    end
  end
  
  # If branch hasn't been specified, create it from the title before
  # validation, replacing spaces with underscore.
  # TODO: do a branch rename inside before_validation_on_update?
  def before_validation
    self.branch ||= title_to_ref(self.title)
  end
  
  # TODO: rename actual branch after branch attribute rename
  def after_create
  end
  
  def branch_from_master
    owner.repository.create_branch(branch)
  end
  
  def copy_to_owner(new_owner)
    duplicate = self.clone
    duplicate.owner = new_owner
    duplicate.title = self.owner.name + "/" + self.title
    duplicate.branch = title_to_ref(duplicate.title)
    duplicate.save!
    
    duplicate.owner.repository.copy_branch_from_repo(
      self.branch, duplicate.branch, self.owner.repository
    )
  end
  
  # TODO: destroy branch on publication destroy
  
  # entry point identifier to use when we're just coming in from a publication
  def entry_identifier
    identifiers.first
  end
  
  protected
    def title_to_ref(str)
      str.tr(' ','_')
    end
end
