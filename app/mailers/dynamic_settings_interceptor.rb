class DynamicSettingsInterceptor
	def self.delivering_email(message)
		settings = Setting.mailer_settings
		
		if settings.mailer_enable == '1'
			override_setting = {
		    address: settings.mailer_server_address,
		    port:    settings.mailer_port.to_i,
		    #domain:  settings.mailer_domain,
		    authentication: "plain",
		    enable_starttls_auto: true,
		    user_name: settings.mailer_username,
		    password:  settings.mailer_password
  		}

  		if settings.mailer_domain.present?
  			override_setting[:domain] = settings.mailer_domain
  		end

			message.delivery_method.settings.merge!(override_setting)
		end
 	end
end