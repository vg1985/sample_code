class CarrierSettingsPolicy < Struct.new(:user, :admin_settings)

	def credit_cards?
		user.is_carrier?
	end

	def update_credit_card_settings?
		user.is_carrier?
	end
end