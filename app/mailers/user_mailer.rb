class UserMailer < Devise::Mailer
	#default from: "admin@sipsurge.com"
	default from: proc{ Setting.mailer_settings.mailer_email }     

  default template_path: 'devise/mailer'
  layout 'mailer'
	
	register_interceptor DynamicSettingsInterceptor

  def confirmation_instructions(record, token, opts={})
    @name = record.name
    super
  end
end
