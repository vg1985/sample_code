class CarrierSetting < ActiveRecord::Base
	belongs_to :carrier
	serialize :kvpairs

	AUTO_RECHARGE_KEYS = [:enable, :storage_id, :balance_threshold, :recharge_amount]
	LOW_CREDIT_NOTI_KEYS = [:enable, :balance_threshold]

	class << self
		def for(carrier, uid)
			case uid
			when 'auto_recharge'
				setting = self.find_or_create_by(carrier_id: carrier.id, uid: 'auto_recharge') do |s|
					s.label = 'Automatic Recharge Setting'
					s.kvpairs = {}
				end
			when 'low_credit_notification'
				setting = self.find_or_create_by(carrier_id: carrier.id, uid: 'low_credit_notification') do |s|
					s.label = 'Low Credit Notification Setting'
					s.kvpairs = {}
				end
			else
				setting = {}
			end

			setting	
		end

		def valid_for_credit_card?(carrier, attrs)
			valid = true
			if(attrs[:auto_recharge_enable].present? && attrs[:auto_recharge_enable] == '1')
				if 	attrs[:auto_recharge_storage_id].blank? || 
						(attrs[:auto_recharge_storage_id].present? && carrier.credit_cards.valid_for_transaction.where(storage_id: attrs[:auto_recharge_storage_id]).blank?) ||
						attrs[:auto_recharge_balance_threshold].blank? || 
						(attrs[:auto_recharge_balance_threshold].present? && !(attrs[:auto_recharge_balance_threshold] !~ /\D/)) ||
						(attrs[:auto_recharge_balance_threshold].present? && attrs[:auto_recharge_balance_threshold].to_i < 0) ||
						attrs[:auto_recharge_recharge_amount].blank? ||
						(attrs[:auto_recharge_recharge_amount].present? && !(attrs[:auto_recharge_recharge_amount] !~ /\D/)) ||
						(attrs[:auto_recharge_recharge_amount].present? && attrs[:auto_recharge_recharge_amount].to_i < 0)

						valid = false
				end
			end

			if(attrs[:lc_notification_enable].present? && attrs[:lc_notification_enable] == '1')
				if attrs[:lc_notification_balance_threshold].blank? || 
					(attrs[:lc_notification_balance_threshold].present? && !(attrs[:lc_notification_balance_threshold] !~ /\D/)) ||
					(attrs[:lc_notification_balance_threshold].present? && attrs[:lc_notification_balance_threshold].to_i < 0)
						
						valid = false
				end
			end

			valid
		end
	end

	AUTO_RECHARGE_KEYS.each do |name|
	  #getter
    define_method("auto_recharge_#{name}") do
      self.kvpairs[name]
    end  
    
    #setter
    define_method("auto_recharge_#{name}=") do |value|
      self.kvpairs[name] = value
    end  
	end

	LOW_CREDIT_NOTI_KEYS.each do |name|
    #getter
    define_method("lc_notification_#{name}") do
      self.kvpairs[name]
    end  
    
    #setter
    define_method("lc_notification_#{name}=") do |value|
      self.kvpairs[name] = value
    end  
	end

end
