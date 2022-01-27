# frozen_string_literal: true

desc 'Dump a database to yaml fixtures.  Set environment variables DB
and DEST to specify the target database and destination path for the
fixtures.  DB defaults to development and DEST defaults to RAILS_ROOT/
test/fixtures.'
task dump_fixtures: :environment do
  path = ENV['DEST'] || "#{RAILS_ROOT}/test/fixtures"
  db   = ENV['DB'] || 'development'
  sql  = 'SELECT * FROM %s'

  ActiveRecord::Base.establish_connection(db)
  %w[documents].each do |table_name|
    i = '000'
    File.open("#{path}/#{table_name}.yml", 'wb') do |file|
      file.write ActiveRecord::Base.connection.select_all(sql %
table_name).each_with_object({}) { |record, hash|
                   hash["#{table_name}_#{i.succ!}"] = record
                 }.to_yaml
    end
  end
end
