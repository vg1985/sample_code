class NotificationMailer < ActionMailer::Base
  register_interceptor DynamicSettingsInterceptor
  
  before_action :setup_mailer_setting

  def accepted_payment(payment)
    @amount = payment.amount
    @carrier = payment.carrier
    @emails = @carrier.carrier_contacts.where(contact_type: ["Primary", "Billing"]).pluck(:email)
    
    send_mail "Payment Added to Ingress Credit"
  end

  def low_credit(carrier)
    @carrier = carrier
    @emails = @carrier.carrier_contacts.where(contact_type: ["Primary", "Billing"]).pluck(:email)
    send_mail "Low Ingress Credit"
  end

  def send_mail(subject)
    if !@emails.empty? && @setup.active
      mail( to: @emails, from: @setup.sender_email, subject: subject, 
        delivery_method_options: @delivery_options)
    else
      mail.perform_deliveries = false
    end
  end

private
  def setup_mailer_setting
    load "#{Rails.root}/app/models/mailer_setting.rb"
    @setup = MailerSetting.setup
    @delivery_options = { address: @setup.address, port: @setup.port, domain: @setup.domain,
        user_name: @setup.username, password: @setup.password }
  end
end
