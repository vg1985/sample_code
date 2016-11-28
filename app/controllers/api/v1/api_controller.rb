module API
  module V1
		class ApiController < ActionController::Base
			include Pundit
			include ApplicationHelper

			before_action :verify_token

			rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

			def verify_token
				if params[:token].present?
					api_token = APIToken.find_by(token: params[:token])
					if api_token.present?
						@carrier = api_token.carrier
					else
						render json: {error: 'Invalid Token.'}, status: :unauthorized and return
					end
				else
					render json: {error: 'Token not present.'}, status: :bad_request and return
				end
			end
		end
	end
end