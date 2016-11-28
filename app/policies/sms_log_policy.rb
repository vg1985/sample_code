class SmsLogPolicy < ApplicationPolicy
	def select_carrier?
		user.is_admin? || user.is_super_admin?
	end

	def index?
		user.is_carrier? || user.is_admin? || user.is_super_admin?
	end

	def show?
		user.is_carrier? || user.is_admin? || user.is_super_admin?
	end

	def create?
		user.is_carrier? || user.is_admin? || user.is_super_admin?
	end

	def edit?
		user.is_admin? || user.is_super_admin?
	end

	def update?
		user.is_admin? || user.is_super_admin?
	end

	def destroy?
		user.is_admin? || user.is_super_admin?
	end

	def apis?
		user.is_carrier?
	end
end