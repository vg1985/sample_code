class ReportPolicy < Struct.new(:user, :reports)
	def module_enabled?
	  user.perms['reports']['module'] == '1'
	end

	def select_carrier?
		user.internal? && user.allowed_carriers.present?
	end

	def profit?
		user.internal? && module_enabled? && user.perms['reports']['profit_report'] == '1'
	end

	def summary?
		module_enabled? && user.perms['reports']['summary_report'] == '1'
	end

	def did?
		module_enabled? && user.perms['reports']['did_report'] == '1'
	end

	def sms?
		module_enabled? && user.perms['reports']['sms_report'] == '1'
	end

	def ingress_pin_down?
		module_enabled? &&
		(user.perms['reports']['summary_report'] == '1' || 
			user.perms['reports']['profit_report'] == '1')
	end

	def egress_pin_down?
		module_enabled? && user.internal? && 
		user.perms['reports']['summary_report'] == '1'
	end

	def get_profit?
		module_enabled? && user.internal? && 
		user.perms['reports']['profit_report'] == '1'
	end

	def get_summary?
		module_enabled? && user.perms['reports']['summary_report'] == '1'
	end

	def get_did?
		module_enabled? && user.perms['reports']['did_report'] == '1'
	end

	def get_sms?
		module_enabled? && user.perms['reports']['sms_report'] == '1'
	end

	def cdr_search?
		module_enabled? && user.perms['reports']['cdr_search'] == '1'
	end
	
	def did_search?
    module_enabled? && user.perms['reports']['cdr_search'] == '1'
  end

	def save_cdr_template?
		module_enabled? && user.perms['reports']['cdr_search'] == '1'
	end

	def cdr_templates?
		module_enabled? && user.perms['reports']['cdr_search'] == '1'
	end

	def remove_cdr_template?
		module_enabled? && user.perms['reports']['cdr_search'] == '1'
	end

	def cdr_logs?
		module_enabled? && user.perms['reports']['cdr_logs'] == '1'
	end

	def username_search?
		user.is_admin? && module_enabled? && user.perms['reports']['cdr_logs'] == '1'
	end
end