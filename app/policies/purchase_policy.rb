class PurchasePolicy < ApplicationPolicy
  def select_customer?
  	user.is_admin?
  end
end