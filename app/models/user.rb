class User < ActiveRecord::Base
  SUPERADMINID = 1

  DT_ADMIN_COLS = [:name, :username, :email, :address1, :country, :is_active]
  devise :database_authenticatable, #:registerable,
         :recoverable, :rememberable, :trackable,
         :masqueradable, :confirmable
  attr_accessor :login

  ## VALIDATIONS ##
  validates :name, length: { in: 2..255 }, presence: true
  validates :role_ids, presence: true, if: Proc.new { internal? }

=begin  
  validates :address1, length: { in: 1..50}, presence: true, if: Proc.new { internal? }
  validates :city, length: { in: 2..25 }, presence: true, if: Proc.new { internal? }
  validates :state, :country, :timezone, presence: true, if: Proc.new { internal? }
  validates :phone1, :mobile, presence: true, if: Proc.new { internal? }
  validates :phone1, :mobile, :phone2, numericality: { only_integer: true },
            allow_blank: true, if: Proc.new { internal? }
=end
  validates :username, length: { in: 5..30 }, format: { with: /\A[a-z0-9]+\Z/i}, presence: true
  validates :name, length: { in: 2..255 }, presence: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}, presence: true
  validates :email, :username, uniqueness: true
  validates :password, presence: true, on: :create
  validates :password, length: { in: 5..15 }, confirmation: true, allow_blank: true

  validate :password_rules

  ## ASSOCIATIONS ##
  has_and_belongs_to_many :roles
  has_one :carrier
  has_many :admins_carriers, foreign_key: :admin_id
  has_many :carriers, through: :admins_carriers
  has_many :credit_cards, through: :carriers
  has_many :sms_numbers
  has_many :payments
  has_many :documents
  has_many :cdr_filter_templates
  has_many :sms_logs

  ## CALLBACKS ##
  #before_validation :generate_password, on: :create, if: :is_admin?
  before_create :skip_confirmation!
  after_create :send_email_to_admin, if: :is_admin?
  after_save :update_zendesk,  if: Proc.new { Setting.zendesk_enabled? }
  before_destroy :destroy_zendesk #should destroy user from zendesk
  #before_create :assign_user_role

  ## SCOPES ##
  scope :admins, -> { where(role_id: Role.admin_id) }
  scope :carriers, -> { where(role_id: Role.carrier_id) }
  scope :internal, -> { where( internal: true ) }
  scope :carriers_only, -> { where( internal: false ) }

  ## INSTANCE METHODS ##

  def is_admin?
    role_ids.include?(Role.admin_id)
    #return true
  end

  def is_super_admin?
    role_ids.include?(Role.admin_id)
  end

  def is_carrier?
    role_ids.include?(Role.carrier_id)
  end

  def carrier_options
    return [] if allowed_carriers.blank?

    if allowed_carriers.include?('-10')
      options = Carrier.all.collect {|c| [c.carrier_balance, c.id]}
    else
      options = Carrier.where(['id IN (?)', allowed_carriers]).all.collect {|c| [c.carrier_balance, c.id]}
    end
  end

  def allowed_carriers
    Rails.cache.fetch("user_#{self.id}_carriers") do
      carriers = []
      self.roles.each do |role|
        carriers += role.carrier_ids
      end
      
      carriers.reject! { |c| c.empty? }
        
      if carriers.include?('-10')
        carriers = ['-10']
      end

      carriers
    end
  end

  def perms
    permissions = Rails.cache.fetch("user_#{self.id}_perms") do
      perms = {}
      self.roles.each do |role|
        perms.deep_merge!(role.perms) if role.perms.present?
      end
      perms
    end

    permissions.present? ? permissions : self.default_permissions
  end

  def default_permissions
    return self.internal? ? Role.default_admin_perms : Role.default_carrier_perms
  end

  def send_otp(for_action = nil)
    current_user.otps.create(action: for_action)
  end

  def default_cdr_filter_template
    CdrFilterTemplate.where(user_id: self.id, is_default: true).first
  end

  def sms_numbers_for_select(is_admin = false)
    dids = Did.sms_enabled.select('id, CONCAT("+1", did) AS did').order('id')

    unless is_admin
      dids = dids.where(['carrier_id = ?', self.carrier.id])
    end

    dids.all.collect{ |r| [r.did, r.id] }
  end

  def ingress_trunks_perms(name)
    self.perms['ingress_trunks'].present? &&
    self.perms['ingress_trunks'][name].present?
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["username = ? OR lower(email) = ?", login, login.downcase ]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_hash).first
    end
  end
  
  def active_for_authentication?
    super && self.is_active # i.e. super && self.is_active
  end

  def self.sync_non_existing
    self.internal.where('zendesk_id IS NULL').all.each do |user|
      if user.role_ids.include?(Role::ADMIN)
        zuser = Zendesk.create_admin(user.name, user.email)
      else
        zuser = Zendesk.create_agent(user.name, user.email)
      end

      if zuser.blank?
        zuser = Zendesk.search_user_by_email(user.email)

        if zuser.present?
          user.update_column('zendesk_id', zuser.id)
        end
      else
        user.update_column('zendesk_id', zuser.id)
      end
    end
  end

  ## PRIVATE METHODS ##

  private
  def generate_password
    self.password = SecureRandom.hex(4)
  end

  def send_email_to_admin
    # Notifier.send_welcome_email(self, password).deliver_now
  end

  def update_zendesk
     if self.zendesk_id.present?
      if self.role_ids.include?(Role::CARRIER)
        Zendesk.delay.update_user(self.zendesk_id, self.name, self.email)
      else
        if self.role_ids.include?(Role::ADMIN)
          Zendesk.delay.update_user(self.zendesk_id, self.name, self.email, 'admin')
        else
          Zendesk.delay.update_user(self.zendesk_id, self.name, self.email, 'agent')
        end
      end
      
    else
      if self.role_ids.include?(Role::ADMIN)
        user = Zendesk.create_admin(self.name, self.email)
      elsif self.role_ids.include?(Role::CARRIER)
        user = Zendesk.create_end_user(self.carrier.zendesk_id, self.name, self.email)
      else
        user = Zendesk.create_agent(self.name, self.email)
      end
      
      self.update_column('zendesk_id', user.id)
    end
  end
  handle_asynchronously :update_zendesk

  def destroy_zendesk
    if self.zendesk_id.present?
      Zendesk.delay.destroy_user(self.zendesk_id)
    end
  end
  
  def password_required?
    !new_record? && (password.present? || password_confirmation.present?)
  end
  
  def assign_user_role
    self.role_id = Role.carrier_id if self.role_id.blank? 
  end

  def password_rules
    return if password.blank?
    
    #if /[!,@,#,$,%,\^,&,*,?,_,~]/.match(password).blank? ||
    if /\d+/.match(password).blank?

        errors.add(:password, 'must contain atleast one number.')
    end
  end
end
