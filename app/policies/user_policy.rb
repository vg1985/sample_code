class UserPolicy < ApplicationPolicy
	def index?
		user.is_admin? || user.is_super_admin?
	end

	def new?
		user.is_admin?
	end

	def create?
		user.is_admin?
	end

	def destroy?
		user.is_admin? && record.id != User::SUPERADMINID
	end

  def edit_internal?
  	user.is_admin? || (user.internal? && user.id == record.id)
  end

  def update_internal?
  	user.is_admin? || (user.internal? && user.id == record.id)
  end
end
