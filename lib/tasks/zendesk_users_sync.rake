namespace :zendesk do
	desc 'Sync Admins and Agents with Zendesk and update their Zendesk IDs'
	task :admins_agents_sync => :environment do
		require 'zendesk'

		client = Zendesk.config_client
		puts 'Fetching users....'
		zusers = client.users(role: ['agent', 'admin']).to_a
		zusers.each do |zuser|
			user = User.find_by(email: zuser.email)
			if user.present?
				puts "User with email #{zuser.email} found...."
				user.update_attribute('zendesk_id', zuser.id)
			end
		end

		puts 'Done'
	end
end