class CarrierPaymentSetting
=begin
  belongs_to :carrier
  belongs_to :credit_card

  validates :carrier, presence: true, uniqueness: true
  validate :verify_credit_card
=end

  def self.enabled
    where enabled: true
  end

  def self.carriers_to_be_charged_ids
    enabled.collect do |setting|
      setting.carrier.id if setting.carrier.ingress_credit <= setting.balance_threshold
    end.compact
  end
  
  def self.carriers_to_be_charged
    Carrier.where id: self.carriers_to_be_charged_ids
  end

  def chargable?
    !(on_monthly_limit? && on_daily_limit?)
  end

  def on_monthly_limit?
    max_monthly_recharge < curr_month_charge + recharge_amount
  end

  def on_daily_limit?
    (max_daily_recharge < curr_day_charge + recharge_amount) || (max_recharge_per_day <= curr_day_charge_count)
  end

  def charge!
    payment = set_payment    
    if payment.auto_purchase_via_credit_card(credit_card_options)
      self.curr_month_charge += self.recharge_amount
      self.curr_day_charge += self.recharge_amount
      self.curr_day_charge_count += 1
      self.save
    end
  end

  def credit_card_options
    options = {}
    options[:number] = credit_card.storage_id
    options[:brand] = credit_card.card_type
    options[:month] = "00"
    options[:year] = "0000"
    options
  end

  def set_payment
    require 'socket'
    
    payment = Payment.create carrier: carrier, user: carrier.user, amount: recharge_amount,
      description: "Auto Recharge", payment_type: "credit_card", 
      ip_address: Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
  end

  private
  def verify_credit_card
    if enabled? && credit_card.nil?
      errors.add(:credit_card, "is missing.")
    end

    if credit_card && !credit_card.valid_for_transaction?
      errors.add(:credit_card, "is not valid for transaction.")
    end
    
    if credit_card && (credit_card.carrier != carrier)
      errors.add(:credit_card, "is not owned by the carrier.")
    end
  end
end
