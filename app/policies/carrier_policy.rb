class CarrierPolicy < ApplicationPolicy
	def module_enabled?
		user.perms['carriers']['module'] == '1'
	end

	def select_carrier?
		user.internal? && user.allowed_carriers.present?
	end

	def index?
		user.internal? && module_enabled? && user.perms['carriers']['list'] == '1'
	end

	def new?
		user.internal? && module_enabled? && user.perms['carriers']['create'] == '1'
	end

	def create?
		user.internal? && module_enabled? && user.perms['carriers']['create'] == '1'
	end

	def list_edit?
		user.internal? && module_enabled? && user.perms['carriers']['update'] == '1'
	end

	def list_destroy?
		user.internal? && module_enabled? && user.perms['carriers']['delete'] == '1'
	end

	def list_enable?
		user.internal? && module_enabled? && user.perms['carriers']['enable'] == '1'
	end

	def list_disable?
		user.internal? && module_enabled? && user.perms['carriers']['disable'] == '1'
	end

	def list_masquerade?
		user.internal? && module_enabled? && user.perms['carriers']['masquerade'] == '1'
	end

	def edit?
		user.internal? && module_enabled? && user.perms['carriers']['update'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.id.to_s))
	end

	def update?
		user.internal? && module_enabled? && user.perms['carriers']['update'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.id.to_s))
	end

	def edit_profile?
		user.carrier.id == record.id
	end

	def update_profile?
		user.carrier.id == record.id
	end

	def enable?
		user.internal? && module_enabled? && user.perms['carriers']['enable'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.id.to_s))
	end

	def disable?
		user.internal? && module_enabled? && user.perms['carriers']['disable'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.id.to_s))
	end

	def destroy?
		user.internal? && module_enabled? && user.perms['carriers']['delete'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.id.to_s))
	end

	def update_bulk_status?
		user.is_admin? || user.is_super_admin?
	end

	def refresh_token?
		user.is_carrier?
	end
	
	def edit_password?
    user.carrier.id == record.id
  end

  def masquerade?
  	user.internal? && module_enabled? && user.perms['carriers']['masquerade'] == '1'
  end

  def masquerade_menu?
  	user.internal? && module_enabled? && user.perms['carriers']['masquerade'] == '1'
  end
end