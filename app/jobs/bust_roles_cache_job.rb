class BustRolesCacheJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    role = Role.find(args[0])
    role.user_ids.each do |user_id|
    	Rails.cache.delete("user_#{user_id}_perms")
    	Rails.cache.delete("user_#{user_id}_carriers")
    end
  end
end
