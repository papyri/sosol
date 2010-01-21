Factory.sequence :name do |n|
  "name_#{n}"
end

Factory.define :board do |f|
  f.title { Factory.next(:name) }
  f.category 'category'
  f.identifier_classes ['DDBIdentifier']
  f.decree_id 1
end

Factory.define :user do |f|
  f.name { Factory.next(:name) }
end

Factory.define :admin, :parent => :user do |f|
  f.admin true
end

Factory.define :decree do |f|
  f.association :board
  f.tally_method Decree::TALLY_METHODS[:percent]
  f.action "approve"
  f.choices "yes"
  f.trigger 0.5
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
  f.choice 'MyString'
end

Factory.define :publication do |f|
  f.association :owner, :factory => :user
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