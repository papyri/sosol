require 'rake/testtask'
namespace :test do
  Rake::TestTask.new(:perseids) do |t| 
    t.libs << "test"
    t.test_files = Dir['test/**/*_test.rb'].select do |path|
      path.include?('treebank_cite') ||
      path.include?('alignment_cite') ||
      path.include?('cite_test') ||
      path.include?('commentary_cite') ||
      path.include?('cts_lib') ||
      path.include?('epi_trans') ||
      path.include?('oac_identifier') 
#      path.include?('oa_cite') ||
#      path.include?('oaj_cite') 
    end
  end
end
