class EscapeComments < ActiveRecord::Migration
  def self.up
    raw_comments = ActiveRecord::Base.connection.execute('SELECT * FROM comments')
    raw_comments.each do |raw_comment|
      puts "#{raw_comment["comment"]}"
      unless raw_comment["comment"].nil?
        escaped_comment = CGI.escape(raw_comment["comment"])
        puts "#{raw_comment["id"]}:\n\t#{raw_comment["comment"]}\n\t#{escaped_comment}"
        ActiveRecord::Base.connection.execute('UPDATE comments SET comment = \''+ escaped_comment + '\' ' + 
                                            'WHERE id = ' + raw_comment["id"].to_s)
      end
    end
  end

  def self.down
    raw_comments = ActiveRecord::Base.connection.execute('SELECT * FROM comments')
    raw_comments.each do |raw_comment|
      puts "#{raw_comment["comment"]}"
      unless raw_comment["comment"].nil?
        unescaped_comment = CGI.unescape(raw_comment["comment"])
        puts "#{raw_comment["id"]}:\n\t#{raw_comment["comment"]}\n\t#{unescaped_comment}"
        ActiveRecord::Base.connection.execute('UPDATE comments SET comment = \''+ unescaped_comment.gsub(/'/, "\\'") + '\' ' + 
                                            'WHERE id = ' + raw_comment["id"].to_s)
      end
    end
  end
end
