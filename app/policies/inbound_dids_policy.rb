class InboundDidsPolicy < Struct.new(:user, :inbound_dids)
  def select_carrier?
    user.is_admin? || user.is_super_admin?
  end

  def rates?
  	user.is_admin?
  end

  def update_local_rates?
  	user.is_admin?
  end

  def update_tf_rates?
  	user.is_admin?
  end

  def manage?
  	user.is_admin?
  end

  def purchase?
  	user.is_admin? || user.is_carrier?
  end

  def search_local_numbers?
  	user.is_admin? || user.is_carrier?
  end

  def search_tf_numbers?
  	user.is_admin? || user.is_carrier?
  end

  def settings?
    user.is_admin? || user.is_carrier?
  end

  def bulk_settings?
    user.is_carrier? || user.is_admin?
  end

  def update_settings?
    user.is_admin? || user.is_carrier?
  end

  def update_bulk_settings?
    user.is_admin? || user.is_carrier?
  end

  def change_defaults?
    user.is_admin?
  end
end