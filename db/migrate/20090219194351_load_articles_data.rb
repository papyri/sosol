require 'active_record/fixtures'

class LoadArticlesData < ActiveRecord::Migration
  def self.up
	down

	directory = File.join(File.dirname(__FILE__), 'dev_data')
	Fixtures.create_fixtures(directory, "articles")
  end

  def self.down
	Article.delete_all
  end
end
