# frozen_string_literal: true

require 'rdoc/task'

# clear the doc:app task et al
begin
  Rake::Task['doc:app'].clear
  Rake::Task['doc/app'].clear
  Rake::Task['doc/app/index.html'].clear
rescue StandardError => e
end

namespace :doc do
  desc 'Generate documentation for the application. Set custom template with TEMPLATE=/path/to/rdoc/template.rb or title with TITLE="Custom Title"'
  RDoc::Task.new('app') do |rdoc|
    rdoc.rdoc_dir = 'doc/app'
    rdoc.template = ENV['template'] if ENV['template']
    rdoc.title    = ENV['title'] || 'Rails Application Documentation'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.options << '--charset' << 'utf-8'
    rdoc.rdoc_files.include('README.rdoc')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.main = 'README.rdoc'
  end
end

desc 'Generate Rails API, Guides, and application documentation'
task doc: ['doc:app', 'doc:rails', 'doc:guides']
