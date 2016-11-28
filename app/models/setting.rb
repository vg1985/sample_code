# Setting Model

class Setting < ActiveRecord::Base
  serialize :kvpairs

  BANDWIDTH_KEYS = [:url, :username, :password, :account,
                    :location, :search_max_numbers]
  INVOICE_KEYS = [:company_name, :company_address, :payment_instructions,
                    :email, :phone, :announcement, :default_billing_cycle]                    
  ZENDESK_KEYS = [:enable, :url, :username, :password, :token, :auth_method, :default_assignee]
  PAYPAL_KEYS = [:enable, :login, :password, :signature, :deduct_commission]
  FINANCE_KEYS = [:allowed_amounts, :auth_file_name, :auth_file_content_type]
  CC_KEYS = [:enable, :gateway, :epay_source_key, :epay_pin]
  MAILER_KEYS = [:enable, :server_address, :port, :domain, :email,
                 :username, :password]
  SMS_KEYS = [:user_id, :api_token, :api_secret]
  SMS_OUTBOUND_KEYS = [:server_address, :port, :domain, :email,
                       :username, :password, :subject, :body]
  SMS_OTHER_KEYS = [:max_recipients, :max_message_size]
  GENERAL_KEYS = [:tnc]
  OTP_KEYS = [:plivo_auth_id, :plivo_auth_token, :plivo_from, :message, :plivo_postback_url, 
              :plivo_postback_method, :twilio_auth_id, :twilio_auth_token, :twilio_from, 
              :twilio_postback_url, :sms_enabled, :email_enabled, :provider]

  BANDWIDTH_KEYS.each do |name|
    # getter
    define_method("bandwidth_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("bandwidth_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  INVOICE_KEYS.each do |name|
    # getter
    define_method("invoice_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("invoice_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  ZENDESK_KEYS.each do |name|
    # getter
    define_method("zendesk_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("zendesk_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  PAYPAL_KEYS.each do |name|
    # getter
    define_method("paypal_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("paypal_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  CC_KEYS.each do |name|
    # getter
    define_method("cc_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("cc_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  MAILER_KEYS.each do |name|
    # getter
    define_method("mailer_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("mailer_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  OTP_KEYS.each do |name|
    # getter
    define_method("otp_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("otp_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  FINANCE_KEYS.each do |name|
    # getter
    define_method("finance_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("finance_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  SMS_KEYS.each do |name|
    # getter
    define_method("sms_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("sms_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  SMS_OUTBOUND_KEYS.each do |name|
    # getter
    define_method("outbound_sms_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("outbound_sms_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  SMS_OTHER_KEYS.each do |name|
    # getter
    define_method("sms_other_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("sms_other_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  GENERAL_KEYS.each do |name|
    # getter
    define_method("general_#{name}") do
      self.kvpairs[name]
    end

    # setter
    define_method("general_#{name}=") do |value|
      self.kvpairs[name] = value
    end
  end

  def self.allowed_amounts_options
    Setting.find_by(uid: 'finance').finance_allowed_amounts.split(',')
  end

  def self.upload_auth_form(file, sanitized_file_name)
    # create directory if not exists
    require 'fileutils'
    directory = Rails.root.join(APP_CONFIG['sample_auth_file_path'])
    FileUtils.mkdir_p directory

    # create the file path
    path = File.join(directory, sanitized_file_name)
    # write the file
    File.open(path, 'wb') { |f| f.write(file.read) }
  end

  def self.mailer_settings
    Setting.find_by(uid: 'mailer')
  end

  def self.outboundsms_settings
    Setting.find_by(uid: 'outbound_sms')
  end

  def self.zendesk_enabled?
    Setting.find_by(uid: 'zendesk').kvpairs[:enable] == '1'
  end

  def self.zendesk_default_assignee
    Setting.find_by(uid: 'zendesk').kvpairs[:default_assignee]
  end

  def self.tnc
    Setting.find_by(uid: 'general').general_tnc
  end

  def self.zendesk_grp_options
    Zendesk.get_groups.collect{ |grp| ["Group: #{grp.name}", grp.id]}
  end

  def self.otp_settings
    Setting.find_by(uid: 'otp')
  end
  
  def self.invoice_settings
    Setting.find_by(uid: 'invoices')
  end

  def self.default_billing_cycle
    invoice_settings.kvpairs[:default_billing_cycle].to_i
  end
end
