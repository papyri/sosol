require 'active_record/fixtures'

class LoadDocumentsData < ActiveRecord::Migration
  def self.up
		down

		directory = File.join(File.dirname(__FILE__), 'dev_data')
		Fixtures.create_fixtures(directory, "documents")
  end

  def self.down
		Document.delete_all
  end
end
