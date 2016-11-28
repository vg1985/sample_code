class SupportPolicy < Struct.new(:user, :support)
	def module_enabled?
    user.perms['support']['module'] == '1'
  end

	def index?
		module_enabled?
	end

	def create_ticket?
		module_enabled? && user.perms['support']['create_ticket'] == '1'
	end

	def update_ticket?
		module_enabled? && user.perms['support']['update_ticket'] == '1'
	end

	def close_ticket?
		module_enabled? && user.perms['support']['close_tickets'] == '1'
	end

	def select_carrier?
		user.internal? && user.allowed_carriers.present?
	end

	def show?
		true
	end

	def comments?
		true
	end

	def destroy?
		module_enabled? && user.perms['support']['delete_tickets'] == '1'
	end

	def status?
		user.is_admin? || user.is_super_admin? || user.is_carrier?
	end

	def make_comment?
		true
	end

	def allow_internal_comment?
		user.internal? && user.allowed_carriers.present?
	end

	def add_tags?
		module_enabled? && user.perms['support']['add_tags'] == '1'
	end

	def merge?
		user.internal? && user.allowed_carriers.present?
	end

  def show_on_zendesk?
    module_enabled? && user.allowed_carriers.present?
  end
end