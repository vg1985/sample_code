class EgressTrunkPolicy < ApplicationPolicy
	def module_enabled?
		user.perms['egress_trunks']['module'] == '1'
	end

	def index?
		user.is_admin? || user.is_super_admin?
	end

	def new?
		user.is_admin? || user.is_super_admin?
	end

	def create?
		user.is_admin? || user.is_super_admin?
	end

	def edit?
		user.is_admin? || user.is_super_admin?
	end

	def update?
		user.is_admin? || user.is_super_admin?
	end

	def activate?
		user.is_admin? || user.is_super_admin?
	end

	def deactivate?
		user.is_admin? || user.is_super_admin?
	end

	def update_bulk_status?
		user.is_admin? || user.is_super_admin?
	end

	def destroy?
		user.is_admin? || user.is_super_admin?
	end

	def bulk_destroy?
		user.is_admin? || user.is_super_admin?
	end
end