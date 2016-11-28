class RegistrationsController < Devise::RegistrationsController
  skip_before_filter :require_no_authentication
  before_filter :update_sanitized_params, if: :devise_controller?

  def update_sanitized_params
		devise_parameter_sanitizer.for(:sign_up) {|u| u.permit([
			:name, :email, :username, :password, :password_confirmation, {role_ids: []},
			:department, :address1, :address2, :city, :state, :country,
			:zip, :timezone, :phone1, :phone2, :mobile, :internal
		])}
  end 
  
  def after_sign_up_path_for(resource)
    users_url # Or :prefix_to_your_route
  end
end
