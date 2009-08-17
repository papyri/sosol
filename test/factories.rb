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