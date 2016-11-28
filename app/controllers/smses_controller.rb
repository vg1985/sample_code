class SmsesController < ApplicationController
	after_action :verify_authorized

  def new
  	authorize :sms_log, :create?

  	setting = Setting.where(uid: 'sms_other').first
  	@settings = [setting.sms_other_max_recipients.to_i, setting.sms_other_max_message_size.to_i, APP_CONFIG['single_sms_length'].to_i]
  end

  def create
  	authorize :sms_log, :create?

  	if policy(:sms_log).select_carrier?
  		did = Did.find_by(id: message_params[:from])
  		carrier = Carrier.find_by(id: message_params[:carrier_id])
  	else
  		carrier = current_user.carrier
  		did = carrier.dids.find_by(id: message_params[:from]) if carrier.present?
  	end

  	recipients = message_params[:recipients].split(',')

    text_size = message_params[:text].size
    max_msg_size = Setting.where(uid: 'sms_other').first.sms_other_max_message_size.to_i

    if text_size > max_msg_size || text_size < 1
      flash[:error] = 'Error: Could not send SMS. Either text is empty or it exceeds the max. limit.'
      redirect_to sms_logs_url and return
    end

  	if carrier.present? && did.present? && recipients.present?
      single_sms_length = APP_CONFIG['single_sms_length']
  		messages_count = (text_size/single_sms_length.to_f).ceil

      if carrier.send_sms_credit?(recipients.size, messages_count)
    		sms_log = carrier.send_sms(current_user.id, did, recipients, messages_count, message_params[:text], message_params[:description])
        flash[:notice] = 'SMS has been processed and you can check its status on this page.'
      else
        flash[:error] = 'Error: Could not complete the request. You do not have enough credit to send this SMS.'
        redirect_to  new_sms_url and return
      end

  		redirect_to sms_logs_url and return
  	else
  		flash[:error] = 'Error: Could not complete the request due to invalid parameters.'
  		redirect_to root_path and return
  	end
  end

  def send_sms_credit
    unless request.xhr?
      render js: "window.location.href='#{root_url}';" and return
    end

    authorize :sms_log, :create?

    if policy(:sms_log).select_carrier?
      user_carrier = Carrier.find(params[:carrier])
    else
      user_carrier = carrier
    end

    single_sms_length = APP_CONFIG['single_sms_length']
    messages_count = (params[:message].size/single_sms_length.to_f).ceil

    respond_to do |format|
      format.text { render text: user_carrier.send_sms_credit?(params[:recipients].to_i, messages_count) }
    end
  end

  def carrier_sms_dids
  	authorize :sms_log, :select_carrier?
  	carrier = Carrier.find(params[:id])
  	@sms_dids = Did.sms_numbers_for_select(carrier.id)
  end

  def apis
    authorize :sms_log, :apis?
    @carrier = carrier
    @api_token = @carrier.api_token

    if @api_token.blank?
      @carrier.api_token.destroy if @carrier.api_token.present?
      @api_token = @carrier.create_api_token
    end

    respond_to do |format|
      format.html {  }
    end
  end

  def manage
    authorize :inbound_dids, :manage?
    @dids = Did.active.all

    respond_to do |format|
      format.html { render 'inbound_dids/manage' }
    end
  end

  def did_groups
    authorize :inbound_dids_groups, :index?

    @did_groups = carrier.did_groups.order('id')
    @grouped_dids = carrier.grouped_dids

    respond_to do |format|
      format.html { render 'inbound_dids_groups/index' }
    end
  end

  private
  def message_params
    params.require(:message).permit(:carrier_id, :from, :recipients, :text, :description)
  end
end
