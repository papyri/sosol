class EscapeComments < ActiveRecord::Migration[4.2]
  def self.up
    #raw_comments = ActiveRecord::Base.connection.execute('SELECT * FROM comments')
    #raw_comments.each do |raw_comment|
    #  escaped_comment = CGI.escape(raw_comment["comment"])
    #  puts "#{raw_comment["id"]}:\n\t#{raw_comment["comment"]}\n\t#{escaped_comment}"
    #  ActiveRecord::Base.connection.execute('UPDATE comments SET comment = \''+ escaped_comment + '\' ' + 
    #                                        'WHERE id = ' + raw_comment["id"].to_s)
    #end
  end

  def self.down
    #raw_comments = ActiveRecord::Base.connection.execute('SELECT * FROM comments')
    #raw_comments.each do |raw_comment|
    #  unescaped_comment = CGI.unescape(raw_comment["comment"])
    #  puts "#{raw_comment["id"]}:\n\t#{raw_comment["comment"]}\n\t#{unescaped_comment}"
    #  ActiveRecord::Base.connection.execute('UPDATE comments SET comment = \''+ unescaped_comment + '\' ' + 
    #                                        'WHERE id = ' + raw_comment["id"].to_s)
    #end
  end
end
