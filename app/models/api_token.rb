class APIToken < ActiveRecord::Base
	belongs_to :carrier

	before_create :create_token

	def create_token
		self.token = SecureRandom.hex
	end
end
