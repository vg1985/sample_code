class UserAction < ActiveRecord::Base
	serialize :info

	DT_ADMIN_COLS = [:created_at, :finished_at, :user_name, :action, :status, :info]

	belongs_to :trackable, polymorphic: true
	belongs_to :owner, class_name: 'User'
	
	has_many :user_action_details

	validates :owner_id, :action, presence: true

	def self.log(trackable, user, action, status, info)
		if user.is_a?(User)
			obj = create(trackable: trackable, owner: user, action: action, status: status, info: info)
		else
			obj = create(trackable: trackable, owner_id: user, action: action, status: status, info: info)
		end

		obj
	end

	def add_detail(status, info)
		user_action_details.create(status: status, info: info)
	end
end
