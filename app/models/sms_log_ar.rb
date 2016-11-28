class SmsLogAr < ActiveRecord::Base
	self.table_name = 'sms_logs'
	DT_COLS = [:message_id, :created_at, :direction, :status, :from_did_no, :recipients, :message]
  DT_ADMIN_COLS = [:company_name, :message_id, :created_at, :direction, :status, :from_did_no, :recipients, :message]

	serialize :recipients
	serialize :additional_info

	belongs_to :user
	belongs_to :carrier
	belongs_to :from_did, class_name: 'Did', foreign_key: 'did_id'

	class << self
		def generate_message_id
			max_id = self.maximum(:id) || 999 #(1000 - 1) - Tracking start from Autoincrement ID 1000
			Date.today.strftime("%Y%m%d-#{max_id + 1}")
		end

		def oldest_record
			self.select('created_at').order('created_at').limit(1).first
		end
	end
end
