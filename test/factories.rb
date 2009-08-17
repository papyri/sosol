Factory.define :board do |f|
  f.title 'board'
  f.category 'category'
  f.decree_id 1
end

Factory.define :user do |f|
  f.name 'John'
end

Factory.define :admin, :parent => :user do |f|
  f.admin true
end

Factory.define :decree do |f|
  f.association :board
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