class CreditCardPolicy < ApplicationPolicy
  def select_carrier?
    user.is_admin?
  end

  def activate?
    user.is_admin?
  end

  def deactivate?
    user.is_admin? 
  end

  def enable?
    user.is_carrier? && user.carrier.credit_cards.exists?(id: record.id)
  end

  def disable?
    user.is_carrier? && user.carrier.credit_cards.exists?(id: record.id)
  end

  def destroy?
    user.is_admin? || 
    (user.is_carrier? && user.carrier.credit_cards.exists?(id: record.id))
  end

  def index?
    user.is_admin? || user.is_carrier?
  end

  def new?
    user.is_carrier?
  end

  def create?
    user.is_carrier?
  end

  def download_authorization?
    user.is_admin? || user.is_super_admin?
  end

  def check_authorization?
    user.is_admin? || user.is_super_admin? ||
     (user.is_carrier? && user.carrier.credit_cards.exists?(id: record.id))
  end

  def remove_attached_authorization?
    user.is_admin? || user.is_super_admin? ||
     (user.is_carrier? && user.carrier.credit_cards.exists?(id: record.id))
  end

  def attach_authorization?
    user.is_admin? || user.is_super_admin? ||
     (user.is_carrier? && user.carrier.credit_cards.exists?(id: record.id))
  end

  def check_nickname?
    user.is_carrier?
  end
end