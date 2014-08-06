require 'rake/testtask'
namespace :test do
  Rake::TestTask.new(:perseids) do |t| 
    t.libs << "test"
    t.test_files = Dir['test/**/*_test.rb'].reject do |path|
      path.include?('ddb_identifier') ||
      path.include?('hgv_meta') ||
      path.include?('numbers_rdf') ||
      path.include?('workflow') ||
      path.include?('decree') ||
      path.include?('/publication')
    end
  end
end
