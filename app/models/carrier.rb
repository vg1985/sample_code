class Carrier < ActiveRecord::Base
  ## CONSTANTS ##
  #DT_ADMIN_COLS = [:company_name, :user_email, :ingress_count, :egress_count, :ingress_credit, :egress_credit, :is_active]
  DT_ADMIN_COLS = [:company_name, :username, :account_code, :user_email, :is_active]

  BILLING_CYCLE_WEEKLY = 0
  BILLING_CYCLE_MONTHLY = 1

  #attr_accessor :user_name, :user_email, :user_password, :user_password_confirm, :carrier_user_update
  scope :active, -> { where(is_active: true) }

  ## VALIDATIONS ##
  validates :account_code, :company_name, :phone1, :mobile, presence: true
  validates :company_name, uniqueness: true
  validates :address1, length: { in: 1..50}, presence: true
  validates :city, length: { in: 2..25 }, presence: true
  validates :state, :country, :timezone, presence: true
  validates :account_code, uniqueness: true, numericality: { only_integer: true }, length: {in: 5..10}
  
  validates :phone1, :mobile, presence: true
  #validates :phone1, :mobile, :phone2, numericality: { only_integer: true }, allow_blank: true
  validate :not_as_primary

  ## ASSOCIATIONS ##
  belongs_to :user, dependent: :destroy
  belongs_to :reseller
  belongs_to :sell_ratesheet
  has_many :contacts, dependent: :destroy
  has_many :ingress_trunks
  has_many :rate_sheets, through: :ingress_trunks
  has_many :active_rate_sheets, -> { where('ingress_trunks.is_active = 1') }, through: :ingress_trunks, source: :rate_sheet
  has_many :egress_trunks
  has_many :admins_carriers, dependent: :destroy
  has_many :admins, through: :admins_carriers, foreign_key: :user_id
  has_many :credit_cards, dependent: :destroy
  #has_one :autocharge_setting, class_name: "CarrierPaymentSetting", dependent: :destroy
  has_one :local_did_rate
  has_one :tollfree_did_rate
  has_one :did_sms_rate
  has_many :orders
  has_many :did_groups
  has_many :dids, through: :did_groups
  has_many :payments
  has_many :sms_logs
  has_one :api_token, dependent: :destroy
  has_many :carrier_balances, dependent: :destroy

  accepts_nested_attributes_for :contacts, allow_destroy: true
  accepts_nested_attributes_for :user, :local_did_rate, :tollfree_did_rate,:did_sms_rate, allow_destroy: true
  validates_associated :contacts, :user


  ## CALLBACKS ##
  before_validation :generate_account_code, on: :create
  after_create :set_carrier_role
  after_save :init_related_data
  before_destroy :destroy_zendesk

  ## SCOPES ##

  ## CLASS METHODS ##
  def self.for_select(include_all = true)
    obj = self.select('id, company_name')

    unless include_all
      obj = obj.active
    end
    
    obj.all.collect do |c|
      [c.company_name, c.id]
    end
  end

  def self.for_support(only_ids = [])
    obj = self.active.select('id, company_name, zendesk_id')
    
    if only_ids.present?
      obj = obj.where(['id IN (?)', only_ids])
    end

    obj.all.collect do |c|
      [c.company_name, c.zendesk_id]
    end
  end
  
  def emails_for_support
    contacts = []

    if self.user.email.present?
      contacts = [["#{self.user.name} <#{self.user.email}>", "#{self.user.zendesk_id}"]]
    end

    contacts = contacts + self.contacts.where('email IS NOT NULL AND email <> ""')
              .collect{ |c| [ "#{c.name} <#{c.email}>", c.zendesk_id ]}
    contacts
  end

  def phones_for_support
    contacts = []

    if self.phone1.present?
      contacts = [["#{self.user.name} <#{self.phone1}>", self.user.zendesk_id]]
    end

    contacts = contacts + self.contacts.where('phone IS NOT NULL AND phone <> ""')
              .collect{ |c| [ "#{c.name} <#{c.phone}>", c.id ]}
    contacts
  end

  def self.for_roles
    self.all.collect{|c| [ c.carrier_balance, c.id ] }
  end

  def self.pro_rate(amount)
    return 0 if amount < 1
    today = Date.today.day
    month_days = Date.today.end_of_month.day

    ((amount/month_days.to_f) * month_days - today).ceil_to(2)
  end

  ## INSTANCE METHODS ##
  def carrier_balance
    "#{company_name} (#{ingress_credit})"
  end

  def primary_contact
    self.user
  end

  def contact_numbers(primary_only = false)
    numbers = [["#{self.user.name} <#{self.mobile}> (Primary)", self.mobile]]

    unless primary_only
      contacts = self.contacts.where('mobile IS NOT NULL && mobile <> ""').all
      numbers = numbers + contacts.collect { |c| ["#{c.name} <#{c.mobile}> (Secondary)", c.mobile]}
    end
    
    numbers
  end

  def contact_emails(primary_only = false)
    emails = [["#{self.user.name} <#{self.user.email}> (Primary)", self.user.email]]

    unless primary_only
      contacts = self.contacts.where('email IS NOT NULL && email <> ""').all
      emails = emails + contacts.collect { |c| ["#{c.name} <#{c.email}> (Secondary)", c.email]}
    end
    
    emails    
  end

  def is_balance_notification_enabled?
    balance_threshold.nil? ? false : true
  end

  def did_rate_by_type(type)
    if 'local' == type 
      @did_rate = self.apt_local_did_rate
    else
      @did_rate =  self.apt_tollfree_did_rate
    end

    @did_rate
  end
  
  def apt_local_did_rate
    if self.local_did_rate.present?
      nested_sql = Array.new
      %w(activation monthly per_minute bill_start bill_increment).each do |col|
        nested_sql << "IFNULL(#{col}, (SELECT #{col} FROM did_rates WHERE carrier_id IS NULL AND type='LocalDidRate')) AS #{col}"
      end
      LocalDidRate.find_by_sql("SELECT id, #{nested_sql.join(',')} FROM did_rates WHERE type='LocalDidRate' AND carrier_id = #{self.id} LIMIT 1")[0]
    else
      LocalDidRate.defaults
    end
    
  end
  
  def apt_tollfree_did_rate
    if self.tollfree_did_rate.present?
      nested_sql = Array.new
      %w(activation monthly per_minute bill_start bill_increment).each do |col| 
        nested_sql << "IFNULL(#{col}, (SELECT #{col} FROM did_rates WHERE carrier_id IS NULL AND type='TollfreeDidRate')) AS #{col}"
      end
      TollfreeDidRate.find_by_sql("SELECT id, #{nested_sql.join(',')} FROM did_rates WHERE type='TollfreeDidRate' AND carrier_id = #{self.id} LIMIT 1")[0]
    else
      TollfreeDidRate.defaults
    end
    
  end

  def apt_sms_did_rate
    if self.did_sms_rate.present?
      nested_sql = Array.new
      %w(activation monthly inbound outbound charge_failed).each do |col|
        nested_sql << "IFNULL(#{col}, (SELECT #{col} FROM did_sms_rates WHERE carrier_id IS NULL)) AS #{col}"
      end
      DidSmsRate.find_by_sql("SELECT id, #{nested_sql.join(',')} FROM did_sms_rates WHERE carrier_id = #{self.id} LIMIT 1")[0]
    else
      DidSmsRate.defaults        
    end
    
  end
  
  def generate_account_code(length = 5)
    self.account_code = Array.new(length){rand(1..9)}.join().to_i
    generate_account_code if Carrier.exists?(account_code: self.account_code)
  end

  def did_purchase_total(type, qty)
    (self.unit_price(type) * qty).ceil_to(2)
  end
  
  def purchase_valid?(type, qty)
    total_price = did_purchase_total(type, qty)
    purchase_eligibility?(total_price)
  end

  def send_sms_credit?(recipients_count, messages_count)
    total_price = sms_total_price(recipients_count, messages_count)
    (self.credit_limit.to_i + self.ingress_credit.to_i) >= total_price
  end

  def sms_activation_credit?(qty = 1)
    total_price = sms_activation_charges(qty) + sms_monthly_charges(qty)
    (self.credit_limit.to_i + self.ingress_credit.to_i) >= total_price
  end

  def purchase_eligibility?(total_price)
    (self.credit_limit.to_i + self.ingress_credit.to_i) >= total_price
  end

  def unit_price(type)
    did_rate =  self.did_rate_by_type(type)
    (did_rate.activation.to_f +  Carrier.pro_rate(did_rate.monthly)).ceil_to(4)
  end

  def did_activation_charges(type, qty = 1)
    did_rate =  self.did_rate_by_type(type)
    (qty * (did_rate.activation.to_f)).ceil_to(4)
  end

  def did_monthly_charges(type, qty = 1)
    did_rate =  self.did_rate_by_type(type)
    (qty * Carrier.pro_rate(did_rate.monthly).to_f).ceil_to(4)
  end

  def sms_total_price(recipients_count, messages_count)
    sms_count = recipients_count * messages_count
    (sms_count * self.apt_sms_did_rate.outbound.to_f).ceil_to(4)
  end

  def sms_activation_charges(qty = 1)
    sms_rate = self.apt_sms_did_rate
    (qty * (sms_rate.activation.to_f)).ceil_to(4)
  end

  def sms_monthly_charges(qty = 1)
    sms_rate = self.apt_sms_did_rate
    (qty * Carrier.pro_rate(sms_rate.monthly).to_f).ceil_to(4)
  end

  def ungrouped_group
    self.did_groups.find_by(name: DidGroup::UNGROUPED_NAME)
  end

  def grouped_dids
    grouping = {}

    self.dids.active.each do |did|
      grouping[did.did_group_id] = [] unless grouping[did.did_group_id].is_a?(Array)
      grouping[did.did_group_id] << did
    end

    grouping
  end

  def send_sms(user_id, did, recipients, messages_count, message, description)
    recipients = [recipients] unless recipients.is_a?(Array)
    response = Sipsurge::BandwidthInterface.send_sms(did.did, recipients, message)
    total_price = 0

    if self.apt_sms_did_rate.charge_failed?
      total_price = sms_total_price(recipients.size, messages_count)
      update_column('ingress_credit', ingress_credit - total_price)
    else
      if response[2] > 0
        total_price = sms_total_price(response[2], messages_count)
        update_column('ingress_credit', ingress_credit - total_price)
      end
    end

    response[1] = [response[1]] unless response[1].is_a?(Array)
    SmsLog.create(carrier_id: self.id, carrier_name: self.company_name, user_id: user_id,
                  did_id: did.id, from_did_no: did.did, recipients: recipients, message: message,
                  direction: 'outgoing', status: response[0], additional_info: response[1],
                  description: description, unit_price: apt_sms_did_rate.outbound.to_f, 
                  total_price: total_price)
  end

  def forward_sms(did, to, messages_count, message, description)
    response = Sipsurge::BandwidthInterface.send_sms(did.did, to, message)
    total_price = 0

    if self.apt_sms_did_rate.charge_failed?
      total_price = sms_total_price(1, messages_count)
      update_column('ingress_credit', ingress_credit - total_price)
    else
      if response[2] > 0
        total_price = sms_total_price(response[2], messages_count)
        update_column('ingress_credit', ingress_credit - total_price)
      end
    end

    response[1] = [response[1]] unless response[1].is_a?(Array)

    SmsLog.create(carrier_id: self.id, carrier_name: self.company_name, did_id: did.id,
                  from_did_no: did.did, recipients: [to], message: message, direction: 'forward', 
                  status: response[0], additional_info: response[1], description: description,
                  unit_price: apt_sms_did_rate.outbound.to_f, total_price: total_price)
  end

  def recieve_sms(did, from, message, serviceMessageID)
    return if did.blank?
    time = Time.now

    inbound_rate = self.apt_sms_did_rate.inbound.to_f
    update_column('ingress_credit', ingress_credit - inbound_rate)

    settings = did.did_sms_settings.first
    forward_sms = false
    forward_email = false
    description = ''

    if ingress_credit > 0
      case settings.dest_type
      when DidSmsSetting::FWDTO_DEST_TYPE
        to = settings.dest_value
        
        message = "New SMS from #{from} to #{did.did}. #{message}"
        text_size = message.size
        max_msg_size = Setting.where(uid: 'sms_other').first.sms_other_max_message_size.to_i

        #truncate to max. msg size
        if text_size > max_msg_size
          message = message[0..max_msg_size]
        end

        single_sms_length = APP_CONFIG['single_sms_length']
        messages_count = (message.size/single_sms_length.to_f).ceil

        if self.send_sms_credit?(1, messages_count)
          description = "Forwarded to #{to}."
          forward_sms = true
        end
      when DidSmsSetting::EMAIL_DEST_TYPE
        email = settings.dest_value
        email_body = Setting.outboundsms_settings.outbound_sms_body
        email_subject = Setting.outboundsms_settings.outbound_sms_subject
        only_time = time.strftime("%I:%M %p")
        date_time = time.strftime("%Y-%m-%d %I:%M %p")
        
        email_body.gsub!('{{sms_body}}', message)
        email_body.gsub!('{{sms_date}}', date_time)
        email_body.gsub!('{{sms_from}}', from)
        email_body.gsub!('{{sms_to}}', did.did)
        
        email_subject.gsub!('{{sms_time}}', only_time)
        email_subject.gsub!('{{sms_from}}', from)
        
        forward_email = true
        description = "Forwarded to email #{email}."
      when DidSmsSetting::API_DEST_TYPE
        url = settings.dest_value
        RestClient.post(url, {message_id: message_id, from: from, to: did.did, text: message, received_at: time.to_s})
        #logger.info 'response....' + response.inspect
        description = "Posted back to URL #{url}."
      end
    end

    if forward_sms
      response = Sipsurge::BandwidthInterface.send_sms(did.did, to, message)
      forward_rate = 0

      if self.apt_sms_did_rate.charge_failed?
        forward_rate = sms_total_price(1, messages_count)
        update_column('ingress_credit', ingress_credit - forward_rate)
      else
        if response[2] > 0
          forward_rate = sms_total_price(response[2], messages_count)
          update_column('ingress_credit', ingress_credit - forward_rate)
        end
      end
      SmsLog.create(carrier_id: self.id, carrier_name: self.company_name, did_id: did.id,
                    from_did_no: did.did, from: from, recipients: [to], message: message,
                    direction: 'forward', status: response[0], description: description,
                    additional_info: response[1] + [{inbound_rate: inbound_rate, forward_rate: forward_rate}],
                    unit_price: inbound_rate + forward_rate, total_price: inbound_rate + forward_rate)
    else
      sms_log =  SmsLog.create(carrier_id: self.id, carrier_name: self.company_name, from: from,
                              recipients: [did.did], message: message, direction: 'incoming',
                              status: 'success', description: description,
                              additional_info: [{ 'messageID': serviceMessageID }],
                              unit_price: apt_sms_did_rate.inbound.to_f,
                              total_price: apt_sms_did_rate.inbound.to_f, created_at: time) 
    end
    
    if forward_email
      email_body.gsub!('{{sms_url}}', "#{APP_CONFIG['host']}/sms_logs?id=#{sms_log.id}")
      InboundsmsMailer.forward(email, email_body, email_subject).deliver
    end
      
  end

  def charge_sms_activation_monthly(activation_charges, monthly_charges, dids, user_id, ip_address)
    if dids.is_a?(Array)
      dids = dids.join(', ')
    end

    ActiveRecord::Base.transaction do
      self.update_column('ingress_credit', self.ingress_credit - (activation_charges + monthly_charges))

      Payment.create({
        carrier_id: self.id, user_id: user_id, amount: activation_charges, 
        payment_type: 'charge', status: 'accepted', ip_address: ip_address,
        description: dids, notes: 'SMS Activated.', charge_type: 'DID SMS Activation'
      })

      Payment.create({
        carrier_id: self.id, user_id: user_id, amount: monthly_charges, 
        payment_type: 'charge', status: 'accepted', ip_address: ip_address,
        description: dids, notes: 'SMS Activated.', charge_type: 'DID SMS Monthly'
      })
    end
  end

  def charge_did_activation_monthly(activation_charges, monthly_charges, dids, user_id, ip_address)
    if dids.is_a?(Array)
      dids = dids.join(', ')
    end

    ActiveRecord::Base.transaction do
      self.update_column('ingress_credit', self.ingress_credit - (activation_charges + monthly_charges))

      Payment.create({
        carrier_id: self.id, user_id: user_id, amount: activation_charges, 
        payment_type: 'charge', status: 'accepted', ip_address: ip_address,
        description: dids, notes: 'DID Activated.', charge_type: 'DID Activation'
      })

      Payment.create({
        carrier_id: self.id, user_id: user_id, amount: monthly_charges, 
        payment_type: 'charge', status: 'accepted', ip_address: ip_address,
        description: dids, notes: 'DID Activated.', charge_type: 'DID Monthly'
      })
    end
  end

  def update_otp_auth_required?(old_contacts_count)
    contacts_changed = self.contacts.size != old_contacts_count

    unless contacts_changed
      self.contacts.to_a.each do |c|
        contacts_changed = true if c.marked_for_destruction?
        
        break if contacts_changed

        if c.mobile_was.present?
          contacts_changed = "#{c.mobile_code}#{c.mobile}".gsub(/[^0-9]/, '') != c.mobile_was.gsub(/[^0-9]/, '')
        else
          contacts_changed = c.mobile.present?
        end

        break if contacts_changed

        if c.email_was.present?
          contacts_changed = c.email != c.email_was
        else
          contacts_changed = c.email.present?
        end

        break if contacts_changed
      end
    end
    
    if self.user.email_changed? || 
       self.phone1_changed? || 
       self.mobile_changed? ||
       contacts_changed

      return true
    end
  end

  def self.sync_non_existing
    Carrier.where('zendesk_id IS NULL').all.each do |carrier|
      org = Zendesk.create_org(carrier.company_name)
      
      if org.blank?
        org = Zendesk.search_org_by_name(carrier.company_name)
      end

      if org.present?
        carrier.update_column('zendesk_id', org.id)
        carrier_user = carrier.user
        end_user = Zendesk.create_end_user(carrier.zendesk_id, carrier_user.name, carrier_user.email)

        if end_user.blank?
          end_user = Zendesk.search_user_by_email(carrier_user.email)

          if end_user.present?
            carrier_user.update_column('zendesk_id', end_user.id)
          end
        else
          carrier_user.update_column('zendesk_id', end_user.id)
        end
        
        carrier.contacts.each do |contact|
          carrier_contact = Zendesk.create_end_user(carrier.zendesk_id, contact.name, contact.email)

          if carrier_contact.blank?
            carrier_contact = Zendesk.search_user_by_email(contact.email)

            if carrier_contact.present?
              contact.update_column('zendesk_id', carrier_contact.id)
            end
          else
            contact.update_column('zendesk_id', carrier_contact.id)
          end
        end
      end
    end
  end
  
  private
  def set_carrier_role
    self.user.roles << Role.find(Role::CARRIER)
  end

  def init_related_data
    #create DID group - ungrouped 
    self.did_groups.find_or_create_by(name: DidGroup::UNGROUPED_NAME)
    
    create_in_zendesk if Setting.zendesk_enabled?
  end

  def create_in_zendesk
    if self.zendesk_id.present? 
      org = Zendesk.update_org(self.zendesk_id, self.company_name)
      unless org.present?
        raise ActiveRecord::Rollback, 'There is an error saving the carrier. Please contact technical administrator.'
      end
    else
      org = Zendesk.create_org(self.company_name)
      if org.present?
        self.update_column('zendesk_id', org.id)
      else
        raise ActiveRecord::Rollback, 'There is an error saving the carrier. Please contact technical administrator.'
      end
    end
  end

  def destroy_zendesk
    if self.zendesk_id.present?
      Zendesk.delay.destroy_org(self.zendesk_id)
    end
  end

  def zendesk_sync_identities
    identities = Zendesk.user_identites(self.zendesk_id)
    identities.each do |identity|
      if 'email' == identity.type
        contact = self.contacts.where(email: identity.value).first
        
        if contact.present?
          contact.update_attribute('zendesk_id', identity.id)
        end
      end
    end
    #<ZendeskAPI::User::Identity {"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/users/1599925012/identities/1009227952.json", "id"=>1009227952, "user_id"=>1599925012, "type"=>"email", "value"=>"vineet@name01.com", "verified"=>true, "primary"=>true, "created_at"=>2015-11-07 11:08:16 UTC, "updated_at"=>2015-11-07 11:08:16 UTC, "undeliverable_count"=>0}>

  end

  def not_as_primary
    emails = []
    mobiles = []

    if contacts.present?
      emails = contacts.collect(&:email)
      mobiles = contacts.collect{ |c| c.mobile_code + c.mobile.gsub(/[()\ -]/, '') }
    end
    
    if emails.include?(user.email)
      errors.add(:email, 'contacts email is same as primary email.')
    end

    if mobiles.include?(self.mobile.gsub(/[()\ -]/, ''))
      errors.add(:mobile, 'contacts mobile is same as primary mobile.')
    end
  end
  
  # def generate_account_code
     # temp = generate_random
     # if Carrier.exists?(account_code: temp)
       # generate_account_code
     # end
     # self.account_code = temp
  # end

end
