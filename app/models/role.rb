class Role < ActiveRecord::Base
	serialize :perms
	serialize :carrier_ids

  ADMIN = 1
  CARRIER = 2

  ## VALIDATIONS ##
  validates :name, presence: true
  validates :name, length: {in: 3..25}, uniqueness: {allow_blank: true}
  validates :carrier_ids, presence: true, unless: Proc.new { internal? }

  has_and_belongs_to_many :users

  scope :visible, -> { where('visible = 1') }

  class << self
  	def admin_id
  		Role::ADMIN
  	end

  	def carrier_id
  		Role::CARRIER
  	end

  	def super_admin_id
  		Role::ADMIN
  	end

    # Default permissions for admin.
    # Used initially, only when seeding the system
    # Should be updated whenever new Modules are added
    # Update def default_carriers_perms also
    # To add new module to existing roles run `rake roles:attach_roles`
    def default_admin_perms(superadmin_access = false)
      perms = ActionController::Parameters.new({
        carriers: {module: '1', list: '1', create: '1', update: '1', delete: '1', disable: '1', enable: '1', masquerade: '1'},
        ingress_trunks: {module: '1', list: '1', create: '1', update: '1', delete: '1', deactivate: '1', activate: '1'},
        egress_trunks: {module: '1', list: '1', create: '1', update: '1', delete: '1', deactivate: '1', activate: '1'},
        support: {module: '1', create_ticket: '1', update_ticket: '1', delete_tickets: '1', add_tags: '1', close_tickets: '1'},
        reports: {module: '1', profit_report: '1', summary_report: '1', cdr_search: '1', cdr_logs: '1', did_report: '1', sms_report: '1'}
      })

      if superadmin_access
        perms[:administrations] = {module: '1', create_role: '1', update_role: '1', masquerade: '1'}
      end

      perms
    end

    # Default permissions for carriers.
    # Used initially, only when seeding the system
    # Should be updated whenever new Modules are added
    # Update def default_admin_perms also
    # To add new module to existing roles run `rake roles:attach_roles`
    def default_carrier_perms
      ActionController::Parameters.new({
        carriers: {module: '0'}, 
        ingress_trunks: {module: '1'}, 
        egress_trunks: {module: '1'},
        support: {module: '1'},
        administrations: {module: '0'},
        reports: {module: '0'}
      })
    end
  end

  def all_carriers_included?

  end
end
