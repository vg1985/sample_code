class Did < ActiveRecord::Base
	STATUS_ACTIVE = 1
	STATUS_SUSPENDED = -1
	STATUS_AGING = 2
	STATUS_DISCONNECTED = 10
	
	REASON_OPTIONS = {
						technical_issue: 'Technical issue', dont_need: 'I don\'t need it anymore', 
						customer_cancelled: 'My customer cancelled', service_issue: 'Service issue', 
						ported: ' Ported to another vendor', other: 'Other'
					}
	belongs_to :carrier
	belongs_to :did_group	
	has_many :did_voice_settings, dependent: :delete_all
	has_many :did_sms_settings, dependent: :delete_all

	scope :active, ->{ where(status: STATUS_ACTIVE) }
	scope :sms_enabled, -> { where(enable_sms: true) }

	def self.sms_numbers_for_select(carrier_id)
	  dids = self.sms_enabled.
	  			 select('id, CONCAT("+1", did) AS did').order('id').
	  			 where(['carrier_id = ?', carrier_id])

	  dids.all.collect{ |r| [r.did, r.id] }
	end

	def set_sms_settings(enable, setting, carrier, deduct_credit = false, user_id = nil, ip_address = nil)
		self.did_sms_settings.clear

		change_status = self.enable_sms == !enable

		if change_status
			self.enable_sms = enable	
		end
		
		self.did_sms_settings = [setting]

		if carrier.present? && enable && change_status
			sms_rate = carrier.apt_sms_did_rate
			self.sms_activation = sms_rate.activation
			self.sms_monthly = sms_rate.monthly

			if deduct_credit
				carrier.charge_sms_activation_monthly(carrier.sms_activation_charges, carrier.sms_monthly_charges, self.did, user_id, ip_address)
			end
		end

		self.save
	end
end
