class PaymentGateway
  BOGUS_GATEWAY = ActiveMerchant::Billing::BogusGateway.new

  CC_GATEWAYS = {
    usaepay: "USA ePay"
  }

  class << self 
    def for_select(include_custom = false)
      options = Hash.new

      if gateway_settings[1].cc_enable == '1'
        options[:credit_card] = "Credit Card" 
      end

      if gateway_settings[0].paypal_enable == '1'
        options[:paypal] = "Paypal" 
      end

      options[:check] = 'Check'
      options[:wire] = 'Wire/ACH'
      options[:bank] = 'Direct Deposit'

      if include_custom
        options[:custom] = "Other" 
      end

      options.invert
    end

    def gateway_settings
      Setting.where(uid: ['paypal', 'cc_payment']).order('id').all
    end

    def paypal_express
      settings = gateway_settings

      paypal_options = {
        login: settings[0].paypal_login,
        password: settings[0].paypal_password,
        signature: settings[0].paypal_signature
      }

      ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
    end

    def usaepay
      settings = gateway_settings

      usaepay_options = {
        login: settings[1].cc_epay_source_key,
        password: settings[1].cc_epay_pin
      }

      ActiveMerchant::Billing::UsaEpayGateway.new(usaepay_options)
    end

    def paypal_deduct_commission?
      setting = Setting.where(uid: 'paypal').first
      setting.paypal_deduct_commission == '1'
    end
  end
end
=begin
class PaymentGateway < ActiveRecord::Base
  serialize :credentials, Hash
  serialize :allowed_amounts, Array
  validates :gateway, uniqueness: true, presence: true, allow_blank: false

  @@credit_card_options = {
    usaepay: "USA ePay"
  }

  @@default_payment_types = {
    wire: 'Wire / ACH',
    bank: 'Bank Deposit',
    custom: "Custom",
    charge: "Charge"
  }

  def self.payment_options
    options = @@default_payment_types
    options[:paypal] = "Paypal" if has_active_paypal?
    options[:credit_card] = "Credit Card"# if has_active_credit_card?

    return options
  end

  def self.payment_options_selection_as_admin
    self.payment_options.collect { |k, v| ["#{v}", "#{k.to_s}"] }
  end

  def self.payment_options_selection_as_carrier
    hash = self.payment_options.reject{ |k| k == :custom }
    hash.collect { |k, v| ["#{v}", "#{k.to_s}"] }
  end

  def self.deactivate_all
    update_all(active: false)
  end

  def activate
    update_attributes active: true
  end

  ### Credit Card Methods
  
  def self.credit_card_options
    @@credit_card_options
  end

  def self.credit_card_selection
    self.credit_card_options.collect { |k, v| ["#{v}", "#{k.to_s}"] }
  end

  def self.credit_cards
    gateways = @@credit_card_options.collect { |k, v| k.to_s }
    self.where(gateway: gateways)
  end

  def self.has_active_credit_card?
    self.credit_cards.where(active: true).blank? ? false : true
  end

  ### Paypal Methods

  def self.has_active_paypal?
    self.where(gateway: "paypal").where(active: true).blank? ? false : true
  end

  ##### CREDS #####
  def self.PAYPAL_EXPRESS_CREDS
    paypal_express_creds = { login: "", password: "", signature: "" }
    self.where(gateway: "paypal").first_or_create(gateway: "paypal", credentials: paypal_express_creds)
  end

  def self.USA_EPAY_CREDS
    usa_epay_creds = { source_key: "", pin: "" }
    self.where(gateway: "usaepay").first_or_create(gateway: "usaepay", credentials: usa_epay_creds)
  end

  ##### GATEWAYS #####
  def self.PAYPAL_EXPRESS_GATEWAY
    paypal_options = {
      login: self.PAYPAL_EXPRESS_CREDS.credentials["login"],
      password: self.PAYPAL_EXPRESS_CREDS.credentials["password"],
      signature: self.PAYPAL_EXPRESS_CREDS.credentials["signature"],
    }
    return Rails.env.test? ? BOGUS_GATEWAY : ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
  end

  def self.USAEPAY_GATEWAY
    usaepay_options = {
      login: self.USA_EPAY_CREDS.credentials["source_key"],
      password: self.USA_EPAY_CREDS.credentials["pin"],
    }
    return Rails.env.test? ? BOGUS_GATEWAY : ActiveMerchant::Billing::UsaEpayGateway.new(usaepay_options)
  end
end
=end