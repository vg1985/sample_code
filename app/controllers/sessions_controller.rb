class SessionsController < Devise::SessionsController
	prepend_before_action :recaptcha, only: [:create]

  # POST /resource/sign_in
  def create
    super
  end

  def recaptcha    
  	if false
  		flash[:alert] = 'Invalid Captcha. Could not login.'
      redirect_to new_user_session_url
    end    
  end
end