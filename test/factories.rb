Factory.sequence :name do |n|
  "name_#{n}"
end

Factory.sequence :email do |n|
  "person#{n}@example.com"
end

Factory.define :board do |f|
  f.title { Factory.next(:name) }
  f.category 'category'
  f.identifier_classes ['DDBIdentifier']
end

Factory.define :hgv_board, :parent => :board do |f|
  f.decrees { |decrees|
    [
      decrees.association(
        :percent_decree,
        :board => nil,
        :trigger => 100.0,
        :action => "accept",
        :choices => "yes no"),
      decrees.association(
        :count_decree,
        :trigger => 1.0,
        :board => nil,
        :action => "reject",
        :choices => "reject"),
      decrees.association(
        :count_decree,
        :trigger => 1.0,
        :board => nil,
        :action => "graffiti",
        :choices => "graffiti")
    ]
  }
end

Factory.define :hgv_meta_board, :parent => :hgv_board do |f|
  f.identifier_classes ['HGVMetaIdentifier']
end

Factory.define :hgv_trans_board, :parent => :hgv_board do |f|
  f.identifier_classes ['HGVTransIdentifier']
end


Factory.define :user do |f|
  f.name { Factory.next(:name) }
  f.email { Factory.next(:email) }
end

Factory.define :admin, :parent => :user do |f|
  f.admin true
end

Factory.define :decree do |f|
  f.association :board
  f.tally_method Decree::TALLY_METHODS[:percent]
end

Factory.define :percent_decree, :parent => :decree do |f|
  f.tally_method Decree::TALLY_METHODS[:percent]
end

Factory.define :count_decree, :parent => :decree do |f|
  f.tally_method Decree::TALLY_METHODS[:count]
end

Factory.define :emailer do |f|
  f.association :board
  f.extra_addresses 'MyText'
  f.include_document 'false'
  f.message 'MyText'
end

Factory.define :event do |f|
  f.category 'commit'
end

Factory.define :vote do |f|
  f.association :user
  f.association :publication
  f.choice :choice #'MyString'
end


Factory.define :publication do |f|
  f.association :owner, :factory => :user
  f.creator { |pub| pub.owner }
  f.title 'MyString'
end

Factory.sequence :hgv_identifier_string do |n|
  "oai:papyri.info:identifiers:hgv:P.Fake:#{n}"
end

Factory.sequence :hgv_number do |n|
  "hgv#{n}"
end

Factory.define :HGVMetaIdentifier do |f|
  f.name { Factory.next(:hgv_identifier_string) }
  f.alternate_name { Factory.next(:hgv_number) }
end

Factory.sequence :ddb_identifier_string do |n|
  "oai:papyri.info:identifiers:ddbdp:0001:1:#{n}"
end

Factory.define :DDBIdentifier do |f|
  f.name { Factory.next(:ddb_identifier_string) }
end

Factory.define :community do |f|
  f.name { Factory.next(:name) }
  f.friendly_name { Factory.next(:name) } 
  f.description 'description'
  f.admins Array.new
end


Factory.define :comment do |f|
  f.comment :comment
  f.user_id :user_id
  f.identifier_id :identifier_id
  f.reason :reason
  f.publication_id :publicaiton_id
  
end
