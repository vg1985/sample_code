class Notifier < ApplicationMailer
	default from: proc{ Setting.mailer_settings.mailer_email }     

	register_interceptor DynamicSettingsInterceptor

  def send_welcome_email(user, password)
    @user = user
    @password = password
    mail(to: user.email, subject: 'Welcome!')
  end

  def send_otp(to, otp_code, otp_id)
  	@otp_id = otp_id
  	@otp_code = otp_code
  	subject = "Your OTP Code for transaction with OTP ID: #{otp_id}"
  	mail(to: to, subject: subject)
  end
end
