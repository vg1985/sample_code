class Otp < ActiveRecord::Base
	include Plivo

	PERMITTED_ACTIONS = %w(
		trunk_update 
		trunk_act_deact 
		trunk_bulk_actdeact 
		carrier_update
		carrier_verify_emobile
	)

	validates :user_id, :otp_code, :action, presence: true
	validates :action, inclusion: { in: PERMITTED_ACTIONS, allow_blank: true }

	before_validation :generate_otp_code

	scope :alive, -> { where(['created_at >= ?', 5.minutes.ago]) }

	def dispatch(via, value)
		status = [false, false]

		otp_setting = Setting.otp_settings.kvpairs

		if 'sms' == via && '1' == otp_setting[:sms_enabled] && value.present?
			message = otp_setting[:message]
			message.gsub!('{{otp_code}}', self.otp_code.to_s)
			message.gsub!('{{otp_id}}', self.id.to_s)
			status[0] = true
			case otp_setting[:provider]
			when '1'
				status[0] = dispatch_with_plivo(otp_setting, message, value)
			when '2'
				status[0] = dispatch_with_twilio(otp_setting, message, value)
			end
		end

		if 'email' == via && '1' == otp_setting[:email_enabled] && value.present?
			#value = 'developer.vineet@gmail.com'
			Notifier.send_otp(value, self.otp_code.to_s, self.id.to_s).deliver_later
			status[1] = true
		end

		status
	end

	def dispatch_with_plivo(otp_setting, message, value)
		require 'plivo'

		request = RestAPI.new(otp_setting[:plivo_auth_id], otp_setting[:plivo_auth_token])

		params = {
			src: otp_setting[:plivo_from],
			dst: value,
			text: message,
			url: otp_setting[:plivo_postback_url],
			method: otp_setting[:plivo_postback_method]
		}

		res = request.send_message(params)

		if res.present? && res.is_a?(Array) && res.size == 2
			LogOtp.create(uuid: res[1]['message_uuid'].first, provider: 'plivo')
		end

		true
	end

	def dispatch_with_twilio(otp_setting, message, value)
		begin
			client = Twilio::REST::Client.new(otp_setting[:twilio_auth_id], otp_setting[:twilio_auth_token])
			message = client.account.messages.create(
    		body: message,
        to: value,
        from: otp_setting[:twilio_from],
        status_callback: otp_setting[:twilio_postback_url]
    	)

    	if message.sid.present?
    		LogOtp.create(uuid: message.sid, provider: 'twilio',
    			destination: message.to, source: message.from,
    			status: message.status, units: message.num_segments,
    			total_amount: message.price, total_rate: message.price)
    	else
    		LogOtp.create(uuid: message.sid, provider: 'twilio',
    			destination: message.to, source: message.from,
    			status: 'undelivered', units: message.num_segments,
    			total_amount: message.price, total_rate: message.price)
    	end
		rescue Twilio::REST::RequestError => e
    	Rails.logger.error "Twilio Error: #{e.message}"
    	return false
		end
		true
	end

	def self.verify(user_id, otpid, otpcode, action)
		otp = self.alive.where(['user_id = ? AND id = ? AND otp_code = ? AND action = ?', 
								user_id, otpid, otpcode, action]).first
		otp.present?
	end

	private

	def generate_otp_code
		self.otp_code = SecureRandom.hex(3)
	end

end
