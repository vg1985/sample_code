class InboundsmsSettingsInterceptor
	def self.delivering_email(message)
		settings = Setting.outboundsms_settings

		override_setting = {
	    address: settings.outbound_sms_server_address,
	    port:    settings.outbound_sms_port.to_i,
	    #domain:  settings.mailer_domain,
	    authentication: "plain",
	    enable_starttls_auto: true,
	    user_name: settings.outbound_sms_username,
	    password:  settings.outbound_sms_password
		}

		if settings.outbound_sms_domain.present?
			override_setting[:domain] = settings.outbound_sms_domain
		end

		message.delivery_method.settings.merge!(override_setting)
		
 	end
end