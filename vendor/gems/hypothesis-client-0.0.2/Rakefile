require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "csv"
require_relative "lib/hypothesis-client"
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

desc "Run a test transformation of a list of annotations"
task :transform, [:filename, :user, :outputdir] do |t,args|
    client = HypothesisClient::Client.new(HypothesisClient::MapperPrototype::JOTH.new)
    output = []
    CSV.foreach(args[:filename], :headers => false) do |row|
      f = row[0]
      path = f.split /\//
      uuid = "pdljann.#{path.last}.1.1"
      data = client.get(f, "urn:cite:perseus:#{uuid}", args[:user])
      output << { 'path' => "#{uuid}.json", 'file' => f, 'data' => data }
    end
    output.each do |a|
      output = File.open(File.join(args[:outputdir],a['path']),'w')
      output << JSON.pretty_generate(a['data'][:data])
      output.close
    end
end


