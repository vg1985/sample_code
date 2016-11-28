class UserActionPolicy < ApplicationPolicy
  def module_enabled?
    user.perms['administrations']['module'] == '1'
  end

  def select_carrier?
    user.is_admin? || user.is_super_admin?
  end

  def index?
  	user.is_admin? || user.is_super_admin?
  end

  def download_details?
  	user.is_admin? || user.is_super_admin?
  end

  def masquerade?
  	user.internal? && module_enabled? && user.perms['administrations']['masquerade'] == '1'
  end

end