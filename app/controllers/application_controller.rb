class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  include Pundit
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :masquerade_user!
  
  include ApplicationHelper

  layout :render_layout
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def render_layout
    if user_signed_in?
      if current_user.internal?
        'admin'
      else
        'carrier'
      end
    else
      'devise'
    end
  end

  def return_not_found(path)
    respond_to do |format|
      format.html do
        flash[:error] = "Record not found"
        return redirect_to path
      end
      format.js { return render "shared/not_found" }
    end
  end

  def admin_only
    unless current_user.is_admin?
      flash[:error] = "You are not authorized to access this page."
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end

  def carrier_only
    unless current_user.is_carrier?
      flash[:error] = "You are not authorized to access this page."
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end

  def user_not_authorized
    @error = 'You are not authorized to perform this action.'
    respond_to do |format|
      format.html { 
        flash[:error] = @error
        redirect_to root_path and return 
      }
      format.js { render 'shared/not_authorized' and return }
    end
    
  end
  
  private
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource)|| root_path
  end

end

