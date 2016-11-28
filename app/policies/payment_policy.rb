class PaymentPolicy < ApplicationPolicy
  def never_hide_transaction_details?
    user.is_admin? || user.is_super_admin?
  end

  def add_note?
    user.is_admin? || user.is_super_admin?
  end

  def set_custom_amount?
    user.is_admin? || user.is_super_admin?
  end

  def carrier_payment_options?
    user.is_admin? || user.is_super_admin?
  end

  def select_carrier?
    user.is_admin? || user.is_super_admin?
  end

  def custom_payment?
    user.is_admin? || user.is_super_admin?
  end
  
  def new?
    user.is_admin? || user.is_carrier?
  end

  def index?
    user.is_admin? || user.is_carrier?
  end

  def create?
    user.is_admin? || user.is_carrier?
  end

  def edit?
    user.is_admin? || (user.is_carrier? && record.carrier_id == user.carrier.id)
  end

  def update?
    user.is_admin? || (user.is_carrier? && record.carrier_id == user.carrier.id)
  end

  def show?
    user.is_admin? || (user.is_carrier? && record.carrier_id == user.carrier.id)
  end

  def accept?
    user.is_admin? || user.is_carrier?
  end

  def cancel?
    record.user_id == user.id
  end

  def set_delete?
    user.is_admin? || user.is_super_admin?
  end

  def add_charge?
    user.is_admin? || user.is_super_admin?
  end

  def charges?
    user.is_admin? || user.is_carrier?
  end
end