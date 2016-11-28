class InboundDidsGroupsPolicy < Struct.new(:user, :inbound_dids_groups)
  def index?
  	user.is_carrier?
  end

  def create?
  	user.is_carrier?
  end

  def edit?
  	user.is_carrier?
  end

  def update?
  	user.is_carrier?
  end

  def destroy?
  	user.is_carrier?
  end

  def update_did_desc?
  	user.is_carrier? || user.is_admin?
  end

  def update_didgrp_desc?
  	user.is_carrier?
  end

  def move_to?
  	user.is_carrier?
  end

  def release?
  	user.is_carrier? || user.is_admin?
  end

  def remove_dids?
    user.is_admin?
  end

  def check_group_name?
  	user.is_carrier?
  end
end