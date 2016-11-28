class UserActionsController < ApplicationController
	before_action :load_trackable
	before_action :load_user_action, only: [:download_details]
	include UserActionsHelper

	def index
		authorize UserAction.new
	end

	def download_details
		authorize UserAction.new, :download_details?

		send_file File.join(Rails.root, 
			                    'app', 
			                    'downloads', 
			                    'import_logs', 
			                    "user_action_#{@user_action.id}.log"
		                    )
	end

	def dt_user_actions_interplay
    authorize UserAction.new, :index?
    
    filter_query = {}

    select_clause = "user_actions.id, users.name AS user_name, user_actions.action, 
    				user_actions.status, user_actions.info, user_actions.created_at,
    				user_actions.finished_at";
    
    order_by = "#{UserAction::DT_ADMIN_COLS[params[:order]["0"][:column].to_i]} #{params[:order]["0"][:dir]}"
    
    @user_actions = @trackable.user_actions.where(filter_query).joins(:owner).select(select_clause).order(order_by)

    @user_actions = @user_actions.page(params[:page]).per(params[:length])
    
    show_details = ['import_csv']

    @data = @user_actions.collect do |ua| 
      [ ua.created_at.in_time_zone(current_user.timezone).to_s(:carrier), 
      	ua.finished_at.present? ? ua.finished_at.in_time_zone(current_user.carrier).to_s(:carrier) : 'NA', 
      	ua.user_name, ua.action.humanize, ua.status.humanize, info_data(ua.info), 
      	(show_details.include?(ua.action) && ua.info.present? && ua.info[:failed_rows].present? && ua.info[:failed_rows] > 0) ? polymorphic_path(['download_details', @trackable, ua])  : '' ]
    end

    respond_to do |format|
      format.json
    end
  end

	private

	def load_trackable
		if params[:rate_sheet_id].present?
			@trackable = RateSheet.find(params[:rate_sheet_id])
		end

		if @trackable.blank?
			respond_to do |format|
				flash[:error] = 'Invalid request'
				format.html {  redirect_to root_url and return }
			end
		end
	end

	def load_user_action
		@user_action = UserAction.find_by(id: params[:id])

		if @user_action.blank?
			respond_to do |format|
				flash[:error] = 'Invalid request'
				format.html {  redirect_to root_url and return }
			end
		end

	end
end
