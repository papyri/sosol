desc 'Dump a database to yaml fixtures.  Set environment variables DB
and DEST to specify the target database and destination path for the
fixtures.  DB defaults to development and DEST defaults to RAILS_ROOT/
test/fixtures.'
task dump_fixtures: :environment do
  path = ENV.fetch('DEST') { "#{RAILS_ROOT}/test/fixtures" }
  db   = ENV.fetch('DB', 'development')
  sql  = 'SELECT * FROM %s'

  ActiveRecord::Base.establish_connection(db)
  %w[documents].each do |table_name|
    i = '000'
    File.binwrite("#{path}/#{table_name}.yml", ActiveRecord::Base.connection.select_all(sql %
table_name).index_by do |_record|
                                                 "#{table_name}_#{i.succ!}"
                                               end.to_yaml)
  end
end
