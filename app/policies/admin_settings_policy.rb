class AdminSettingsPolicy < Struct.new(:user, :admin_settings)

	def bandwidth?
		user.is_admin?
	end

	def update_bandwidth_settings?
		user.is_admin?
	end

	def invoices?
		user.is_admin?
	end

	def update_invoice_settings?
		user.is_admin?
	end

	def zendesk?
		user.is_admin?
	end

	def update_zendesk_settings?
		user.is_admin?
	end

	def mailer?
		user.is_admin?
	end

	def update_mailer_settings?
		user.is_admin?
	end

	def otp?
		user.is_admin?
	end

	def update_otp_settings?
		user.is_admin?
	end

	def payment_gateways?
		user.is_admin?
	end

	def update_payment_settings?
		user.is_admin?
	end

	def finance?
		user.is_admin?
	end

	def update_finance_settings?
		user.is_admin?
	end

	def sms?
		user.is_admin?
	end

	def update_sms_settings?
		user.is_admin?
	end

	def general?
		user.is_admin?
	end

	def update_general_settings?
		user.is_admin?
	end

	def export_non_existing?
		user.is_admin?
	end

	def export_to_zendesk?
		user.is_admin?
	end
end