class Contact < ActiveRecord::Base
  attr_accessor :phone_code, :mobile_code, :primary_email
  ## CONSTANTS ##
  TYPES = {
            business_owner: 'Business Owner', accounting: 'Accounting',
            technical: 'Technical', other: 'Other'
          }
  
  ## VALIDATIONS ##
  validates :email, :phone, :mobile, presence: true
  validates :email, uniqueness: true,
    format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates :phone, format: { with: /\A[\d\ \(\)-]+\Z/ }
  validates :mobile, uniqueness: true, format: { with: /\A[\d\ \(\)-]+\Z/ }

  ## ASSOCIATIONS ##
  belongs_to :carrier
  before_save :add_codes
  before_destroy :destroy_zendesk, if: Proc.new { Setting.zendesk_enabled? }
  after_save :update_zendesk, if: Proc.new { Setting.zendesk_enabled? }
  
  private
  def add_codes
    if self.phone.present?
      self.phone = "#{self.phone_code} #{self.phone}"
    end

    if self.mobile.present?
      self.mobile = "#{self.mobile_code} #{self.mobile}"
    end
  end

  def update_zendesk
    if self.email.present?
      if self.zendesk_id.present?
        Zendesk.delay.update_user(self.zendesk_id, self.name, self.email)
      else
        user = Zendesk.create_end_user(self.carrier.zendesk_id, self.name, self.email)
        self.update_column('zendesk_id', user.id)
      end
    end
  end
  handle_asynchronously :update_zendesk

  def destroy_zendesk
    if self.zendesk_id.present?
      Zendesk.delay.destroy_user(self.zendesk_id)
    end
  end
end
