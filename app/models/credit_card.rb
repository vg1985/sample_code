class CreditCard < ActiveRecord::Base
  DT_ADMIN_COLS = [:company_name, :nickname, :card_number, :card_type, :expired_on, :created_at]
  acts_as_paranoid
  
  belongs_to :carrier
  has_many :documents, as: :documentable, dependent: :destroy
  
  accepts_nested_attributes_for :documents, allow_destroy: true

  delegate :user, to: :carrier, allow_nil: false

  validates :carrier_id, :expired_on, :city_state, presence: true
  validates :nickname, presence: true, format: {with: /\A[a-z0-9\s]+\z/i}, length: {in: 2..20}, uniqueness: {scope: :carrier_id}
  validates :zip_code, presence: true, length: {minimum: 2}
  validates :other_city_state, presence: true, length: {minimum: 2}, if: Proc.new { |cc| cc.city_state.downcase == 'other' }
  validates_associated :documents

  validates :storage_id, uniqueness: { allow_blank: true }

  before_create :set_for_confirmation

  def self.valid_for_transaction
    where(enabled: true, active: true)
  end

  def self.unconfirmed
    unscoped.where(on_cloud: false)
  end

  def self.for_select(carrier, include_other = false) 
    options = []

    if carrier.credit_cards.present?
      options = carrier.credit_cards.valid_for_transaction.collect do |cc|
        [cc.nickname, cc.storage_id]
      end
    end
    if include_other
      options << ['Other', '-1']
    end

    options
  end

  def self.usaepay_authorize(amount, cc_options)
    require 'usaepay'
    
    tran = UmTransaction.new
    setting = Setting.where(uid: 'cc_payment').first
    tran.key = setting.cc_epay_source_key
    tran.usesandbox = ActiveMerchant::Billing::Gateway.new.test?
    tran.card = cc_options[:number]
    tran.exp = '0000'
    tran.amount = amount.to_s
    tran.street = cc_options[:address]
    tran.zip = cc_options[:zip_code]

    tran.process
    tran
  end

  def status?
    active? ? "Active" : "Inactive"
  end

  def verified?
    active?
  end

  def expiration_date
    expired_on.end_of_month.to_s(:db)
  end

  def description
    "#{nickname}(#{card_type}-#{card_number})"
  end
  def valid_for_transaction?
    active && enabled
  end

  def disable
    update_attributes enabled: false
  end

  def enable
    update_attributes enabled: true
  end

  def deactivate
    already_deactivated = !active
    self.update_attributes active: false
    notify_deactivation unless already_deactivated
  end

  def activate
    already_activated = active
    update_attributes active: true
    notify_activation unless already_activated
  end

  def set_as_on_cloud
    notify_creation and return true if self.update_attributes on_cloud: true
  end

private
  def set_for_confirmation
    self.on_cloud = false
    self.redir_ref = SecureRandom.hex(8)
  end

  def notify_creation
    params = {
      for_admin: true,
      user_id: self.user.id,
      message: "A Credit Card Application was submitted.",
      link: "/credit_cards"
    }
    Notification.create!(params)
  end

  def notify_activation
    params = {
      for_admin: false,
      user_id: self.user.id,
      message: "Your Credit Card was deactivated.",
      link: "/credit_cards"
    }
    Notification.create!(params)
  end

  def notify_deactivation
    params = {
      for_admin: false,
      user_id: self.user.id,
      message: "Your Credit Card was deactivated.",
      link: "/credit_cards"
    }
    Notification.create!(params)
  end
end
