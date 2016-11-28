class OtpsController < ApplicationController
	skip_before_action :authenticate_user!, only: [:uemobile_auth_dialog]

	def auth_dialog
		@contact_numbers = current_user.carrier.contact_numbers
		@contact_emails = current_user.carrier.contact_emails
		@otp_settings = Setting.otp_settings.kvpairs

		respond_to do |format|
      format.html { render layout: false }
    end
	end

	def primary_auth_dialog
		@contact_numbers = current_user.carrier.contact_numbers(true)
		@contact_emails = current_user.carrier.contact_emails(true)

		@otp_settings = Setting.otp_settings.kvpairs

		respond_to do |format|
      format.html { render action: :auth_dialog, layout: false }
    end
	end

	def uemobile_auth_dialog
		@invalid_request = true

		if params[:element].blank? || 
				params[:value].blank? ||
				!(%w(email mobile).include?(params[:element]))

			@error = 'Error: Invalid parameters.'
		end

		if 'email' == params[:element]
			if User.find_by(email: params[:value]).blank?
				@otp = Otp.create(user_id: -1, action: params[:a])
				session['email_to_verify'] = params[:value]

				dispatch_status = @otp.dispatch('email', params[:value])
				@message = "The OTP has been sent to your email #{params[:value]}."
			else
				@error = 'Invalid Email. It is already present with us.'
			end
		elsif 'mobile' == params[:element]
			@otp = Otp.create(user_id: -1, action: params[:a])
			session['mobile_to_verify'] = params[:value]
			dispatch_status = @otp.dispatch('sms', session['mobile_to_verify'].gsub(/[^+0-9]/, ''))
			@message = "The SMS containing OTP has been sent to your mobile #{params[:value]}."
		end

		respond_to do |format|
      format.html { render layout: false }
    end
	end

	def generate
		if params[:via].blank? || !(%w(sms email).include?(params[:via]))
			respond_to do |format|
				format.json { render json: {response: 'error', 
																	message: 'Invalid request.'} and return}
			end																
		end

		if ('sms' == params[:via])
			carrier = current_user.carrier
			unless ([carrier.mobile] + carrier.contacts.collect(&:mobile)).include?(params[:mobile])
				respond_to do |format|
					format.json { render json: {response: 'error', 
																		message: 'Could not find this mobile number. OTP cannot be sent.'} and return}
				end
			end
		end

		if ('email' == params[:via])
			carrier = current_user.carrier
			unless ([current_user.email] + carrier.contacts.collect(&:email)).include?(params[:email])
				respond_to do |format|
					format.json { render json: {response: 'error', 
																		message: 'Could not find this email address. OTP cannot be sent.'} and return}
				end
			end
		end

		otp = Otp.create(user_id: current_user.id, action: params[:a])

		if otp.id.present?
			if 'sms' == params[:via]
				#otp.dispatch(params[:mobile], carrier.user.email)
				dispatch_status = otp.dispatch('sms', params[:mobile])
			end

			if 'email' == params[:via]
				dispatch_status = otp.dispatch('email', params[:email])
			end
		end

		logger.error 'otp errors....' + otp.errors.messages.inspect
		device_order = []
		
		if dispatch_status[0]
			device_order << "on your mobile \"#{params[:mobile]}\""
		end

		if dispatch_status[1]
			device_order << "on your email \"#{params[:email]}\""
		end

		success_message = "OTP has been successfully sent #{device_order.to_sentence}. 
											Please note this OTP will remain active for another 5 minutes before expiring."

		respond_to do |format|
      format.json { render json: {response: 'success', message: success_message, id: otp.id, code: otp.otp_code} }
    end
	end
end