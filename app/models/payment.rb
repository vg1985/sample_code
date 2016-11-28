class Payment < ActiveRecord::Base
  DT_COLS = [:payment_type, :for_date, :amount, :status, :description, :notes]
  DT_ADMIN_COLS = [:company_name, :payment_type, :for_date, :amount, :status]

  DT_CHARGES_COLS = [:charge_type, :for_date, :amount, :status, :description, :notes]
  DT_ADMIN_CHARGES_COLS = [:company_name, :charge_type, :for_date, :amount, :status]

  belongs_to :user
  belongs_to :carrier

  validates :amount, presence: true, numericality: { greater_than: 0.0, allow_blank: true }
  validates :carrier_id, presence: true
  validates :transaction_details, :description, :custom_type, length: { maximum: 250 }
  validates :custom_type, presence: { if: lambda { |a| a.payment_type == 'custom' } }
  validates :charge_type, presence: { if: Proc.new {|p| p.payment_type == 'charge' } }

  #default_scope { order('created_at DESC') }
  scope :except_charges, -> { where(["payment_type != 'charge'"]) }
  scope :charges_only, -> { where("payment_type = 'charge'") }
  after_create :notif_creation

  def self.pending
    where(status: 'pending')
  end
  def self.accepted
    where(status: 'accepted')
  end
  def self.cancelled
    where(status: 'cancelled')
  end
  def self.non_manual
    where('payment_type = "paypal" OR payment_type = "credit_card"')
  end
  
  def accepted?
    return true if status == 'accepted'
  end
  def cancelled?
    return true if status == 'cancelled'
  end

  def amount_to_cents
    begin
      amount*100 
    rescue
      0
    end
  end

  def approve(transaction_id = nil)
    return false if status != 'pending'

    ActiveRecord::Base.transaction do
      self.balance_old = self.carrier.ingress_credit
      self.balance_new = self.balance_old + self.amount
      
      self.carrier.ingress_credit += self.amount
      self.carrier.save(validate: false)

      self.transaction_details = transaction_id if transaction_id.present?
      self.status = 'accepted'
      self.save
    end

    #NotificationMailer.accepted_payment(self).deliver
    notif_acceptance
  end
  
  def decline(message = nil)
    return false if status == 'declined'
    
    self.update(status: 'declined', decline_reason: message)
    notif_cancellation
  end

  def charge
    return false if status != 'pending' || !self.carrier.purchase_eligibility?(self.amount)
    
    ActiveRecord::Base.transaction do
      self.balance_old = self.carrier.ingress_credit
      self.balance_new = self.balance_old - self.amount
      
      self.carrier.ingress_credit -= self.amount
      self.carrier.save(validate: false)
      
      self.status = 'accepted'
      self.save
    end

    return true
  end

  def set_delete(deduct)
    return false if status == 'deleted'

    if status == 'accepted' && deduct
      self.carrier.ingress_credit -= self.amount
      self.carrier.save
    end
    
    self.update_attributes(status: 'deleted')
    #notif_deleted
  end

  def credit_card_capture(ip)
    gateway = PaymentGateway.usaepay
    self.ip_address = ip && self.save
    response = gateway.capture(amount_to_cents, transaction_token, ip: ip_address)
    
    if response.success?
      approve("Auth Code: #{response.params["auth_code"]}, Reference Number: #{response.authorization}")
      return true
    else
      decline(response.message)
      return false
    end
  end

  def auto_purchase_via_credit_card(credit_card_options)
    gateway = PaymentGateway.USAEPAY_GATEWAY
    credit_card = ActiveMerchant::Billing::CreditCard.new(credit_card_options)
    response = gateway.purchase(amount_to_cents, credit_card, 
      payment_options)
     
     if response.success?
      approve("Auth Code: #{response.params["auth_code"]}, Reference Number: #{response.authorization}")
      return true
    else
      decline(response.message)
      return false
    end
  end

  def paypal_purchase(ip)
    gateway = PaymentGateway.paypal_express
    details = gateway.details_for(self.transaction_token)
    
    express_purchase_options = { ip: self.ip_address, token: self.transaction_token, payer_id: self.payer_id }
    response = gateway.purchase(amount_to_cents, express_purchase_options)
    
    if response.success?
      #Order will be approved through IPN
      #approve
      return true
    else
      decline(response.message)
      return false
    end
  end

  def final?
    status != 'pending'
  end

  def manual_payment?
    %w{check wire bank charge custom}.include?(payment_type)
  end

  def payment_options
    options = {}
    options[:ip_address] = ip_address
    options[:address] = {}
    options[:address][:company] = carrier.company_name
    options[:address][:address1] = carrier.address1
    options[:address][:address2] = carrier.address2
    options[:address][:city] = carrier.city
    options[:address][:state] = carrier.state
    options[:address][:zip] = carrier.zip
    options
  end

private
  def notif_creation
    params = {
      for_admin: self.user.carrier,
      user_id: self.user.id,
      message: "A payment was recorded for #{self.carrier.company_name}.",
      link: "/payments"
    }
    Notification.create!(params)
  end
  def notif_acceptance
    params = {
      for_admin: false,
      user_id: self.user.id,
      message: 'One of your recent payments was accepted.',
      link: '/payments'
    }
    Notification.create!(params)
  end
  def notif_cancellation
    params = {
      for_admin: false,
      user_id: self.user.id,
      message: 'One of your recent payments was cancelled.',
      link: '/payments/#{id}'
    }
    Notification.create!(params)
  end
end
