class OrderPolicy < ApplicationPolicy

  def select_carrier?
    user.is_admin? || user.is_super_admin?
  end

  def index?
  	true
  end

  def show?
  	user.is_admin? || (user.is_carrier? && record.carrier_id == user.carrier.id)
  end
end