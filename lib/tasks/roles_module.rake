namespace :roles do
	desc 'Add new module in already saved roles'
	# Run when new module needs to be added in exisitng roles
  	# Update `def default_admin_perms` and
  	# `def default_carrier_perms` also in role.rb
  	# rake roles:add_new_module['modulename']
	task :add_new_module, [:module] => :environment do |t, args|
		puts "Adding new module #{args[:module]}..."
		puts 'Pulling all roles....'

		Role.all.each do |role|
			next if role.perms.keys.include?(args[:module])
			if role.id == Role::ADMIN
				role.perms = role.perms.merge({args[:module] => {'module': '1'}})
			else
				role.perms = role.perms.merge({args[:module] => {'module': '0'}})
			end

			puts "Saving perms for Role #{role.name}"
			role.save

			puts 'Busting users perm cache...'
			role.user_ids.each do |user_id|
				Rails.cache.delete("user_#{user_id}_perms")
			end
		end
		
		puts 'Done'
	end

	# Run after seeds.rb
	desc 'Attach roles to existing users'
	task :attach => :environment do
		puts 'Attaching roles to carriers...'
		
		Carrier.all.each do |c|
			c.user.role_ids = [Role::CARRIER]
			c.save
		end
		
		puts 'Done'
	end

	desc 'Bust the roles cache'
	task :bust_cache, [:module] => :environment do
		puts 'Busting roles cache for all users....'

		User.all.each do |u|
			Rails.cache.delete("user_#{u.id}_perms")
			Rails.cache.delete("user_#{u.id}_carriers")
		end
		
		puts 'Done'
	end
end