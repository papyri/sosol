namespace :rpx do
  desc "Unmaps all user mappings for the current environment and drops them from the database"
  task :unmap => :environment do
    @rpx = Rpx::RpxHelper.new(RPX_API_KEY, RPX_BASE_URL, RPX_REALM)
    @users = User.find(:all)
    
    for user in @users
      identifiers = @rpx.mappings(user.id)
      # clear all identifiers
      for identifier in identifiers
        @rpx.unmap(identifier, user.id)
        puts "Mapping #{user.id} => #{identifier} removed"
      end
      user.destroy
    end
  end
  
  desc "Converts all remote RPX mappings to local mappings then unmaps the remote mapping"
  task :convert_to_local => :environment do
    @rpx = Rpx::RpxHelper.new(RPX_API_KEY, RPX_BASE_URL, RPX_REALM)
    mappings = @rpx.all_mappings
    
    mappings.each_pair do |user_id, identifier|
      begin
        user = User.find(user_id)
        user.user_identifiers << UserIdentifier.create(:identifier => identifier)
      
        @rpx.unmap(identifier, user_id)
        puts "Mapping #{user_id} => #{identifier} removed"
      
        puts "Current mappings for #{user.name}:"
        user.user_identifiers.each{|i| puts i.identifier}
      rescue StandardError => e
        puts "An error occurred: #{e.inspect}"
      end
    end
  end
end
