class IngressTrunkPolicy < ApplicationPolicy
	def module_enabled?
		user.perms['ingress_trunks']['module'] == '1'
	end

	def select_carrier?
		user.internal? && user.allowed_carriers.present?
	end

	def index?
		module_enabled? && user.perms['ingress_trunks']['list'] == '1'
	end

	def list_edit?
		module_enabled? && user.perms['ingress_trunks']['update'] == '1'
	end

	def list_delete?
		user.internal? && module_enabled? && user.perms['ingress_trunks']['delete'] == '1'
	end

	def list_activate?
		module_enabled? && user.perms['ingress_trunks']['activate'] == '1'
	end

	def list_deactivate?
		module_enabled? && user.perms['ingress_trunks']['deactivate'] == '1'
	end

	def new?
		user.internal? && module_enabled? && user.perms['ingress_trunks']['create'] == '1'
	end

	def create?
		user.internal? && module_enabled? && user.perms['ingress_trunks']['create'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.carrier_id.to_s))
	end

	def edit?
		module_enabled? && user.perms['ingress_trunks']['update'] == '1' &&
		(user.internal && (user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.carrier_id.to_s)) ||
			(!user.internal && user.carrier.ingress_trunks.exists?(id: record.id)))
	end

	def update?
		module_enabled? && user.perms['ingress_trunks']['update'] == '1' &&
		(user.internal && (user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.carrier_id.to_s)) ||
			(!user.internal && user.carrier.ingress_trunks.exists?(id: record.id)))
	end

	def activate?
		module_enabled? && user.perms['ingress_trunks']['activate'] == '1' &&
		(user.internal && (user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.carrier_id.to_s)) ||
			(!user.internal && user.carrier.ingress_trunks.exists?(id: record.id)))
	end

	def deactivate?
		module_enabled? && user.perms['ingress_trunks']['deactivate'] == '1' &&
		(user.internal && (user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.carrier_id.to_s)) ||
			(!user.internal && user.carrier.ingress_trunks.exists?(id: record.id)))
	end

	def update_bulk_status?
		module_enabled? && 
		(user.perms['ingress_trunks']['activate'] == '1' || user.perms['ingress_trunks']['deactivate'] == '1')
	end

	def destroy?
		user.internal && module_enabled? && user.perms['ingress_trunks']['delete'] == '1' &&
		(user.allowed_carriers.include?('-10') || user.allowed_carriers.include?(record.carrier_id.to_s))
	end

	def bulk_destroy?
		user.internal && module_enabled? && user.perms['ingress_trunks']['delete'] == '1' 
	end
end