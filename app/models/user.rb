#Represents a system user.
class User < ActiveRecord::Base

  validates_uniqueness_of :name, :case_sensitive => false

  has_many :user_identifiers, :dependent => :destroy

  has_many :communities_members
  has_many :community_memberships, :through => :communities_members, :source => :community
  has_many :communities_admins
  has_many :community_admins,  :through => :communities_admins, :source => :community

  has_many :boards_users
  has_many :boards, :through => :boards_users
  has_many :finalizing_boards, :class_name => 'Board', :foreign_key => 'finalizer_user_id'

  has_and_belongs_to_many :emailers

  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner, :dependent => :destroy

  has_many :comments

  has_repository

  after_create do |user|
    user.repository.create

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
        user.admin = true
        user.save!

        Sosol::Application.config.dev_init_files.each do |pn_id|
          p = Publication.new
          p.owner = user
          p.creator = user
          p.populate_identifiers_from_identifiers(pn_id)
          p.save!
          p.branch_from_master

          e = Event.new
          e.category = "started editing"
          e.target = p
          e.owner = user
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

  def jgit_actor
    org.eclipse.jgit.lib.PersonIdent.new(self.full_name, self.email)
  end

  # Copied from: https://raw.github.com/mojombo/grit/v2.4.1/lib/grit/actor.rb
  # Outputs an actor string for Git commits.
  #
  #   actor = Actor.new('bob', 'bob@email.com')
  #   actor.output(time) # => "bob <bob@email.com> UNIX_TIME +0700"
  #
  # time - The Time the commit was authored or committed.
  #
  # Returns a String.
  def output(time)
    out = @name.to_s.dup
    if @email
      out << " <#{@email}>"
    end
    hours = (time.utc_offset.to_f / 3600).to_i # 60 * 60, seconds to hours
    rem   = time.utc_offset.abs % 3600
    out << " #{time.to_i} #{hours >= 0 ? :+ : :-}#{hours.abs.to_s.rjust(2, '0')}#{rem.to_s.rjust(2, '0')}"
  end

  def author_string
    "#{self.full_name} <#{self.email}>"
  end

  def git_author_string
    local_time = Time.now
    "#{self.author_string} #{local_time.to_i} #{local_time.strftime('%z')}"
  end

  before_destroy do |user|
    user.repository.destroy
  end

  #Sends an email to all users on the system that have an email address.
  #*Args*
  #- +subject_line+ the email's subject
  #- +email_content+ the email's body
  def self.compose_email(subject_line, email_content)
    #get email addresses from all users that have them
    #users = User.find(:all, :select => "email", :conditions => ["email != ?", ""])
    users = User.find_by_sql("SELECT email From users WHERE email is not null")

    users.each do |toaddress|
      if toaddress.email.strip != ""
        EmailerMailer.general_email(toaddress.email, subject_line, email_content).deliver
      end
    end

    #can use below if want to send to all addresses in 1 email
    #format 'to' addresses for actionmailer
    #addresses = users.map{|c| c.email}.join(", ")
    #EmailerMailer.deliver_send_email_out(addresses, subject_line, email_content)

  end

  def self.stats(user_id)
    if user_id.is_a? Integer
      stats = ActiveRecord::Base.connection.execute("select p.id AS pub_id, p.title AS pub_title, p.status AS pub_status, i.title AS id_title, c.comment AS comment, c.reason AS reason, c.created_at AS created_at from comments c LEFT OUTER JOIN publications p ON c.publication_id=p.id LEFT OUTER JOIN identifiers i ON c.identifier_id=i.id where c.user_id=#{user_id} ORDER BY c.created_at;")
      stats.each {|row|
        row["created_at"] = DateTime.parse(row["created_at"])
        unless row["comment"].nil?
          row["comment"] = URI.unescape(row["comment"]).gsub("+", " ")
        end
        }
    end
  end
end
