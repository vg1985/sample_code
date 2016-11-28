class UserActionDetail < ActiveRecord::Base
	serialize :info
	
	belongs_to :user_action
end
