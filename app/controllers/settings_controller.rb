class SettingsController < ApplicationController
  after_action :verify_authorized

  def general
    authorize :admin_settings, :general?

    @general_setting = Setting.find_by(uid: 'general')

    respond_to do |format|
      format.html
    end
  end

  def update_general_settings
    authorize :admin_settings, :update_general_settings?

    unless request.xhr?
      render js: 'window.location.href="/settings/general";' and return
    end

    @general_setting = Setting.find_by(uid: 'general')
    
    if @general_setting.blank?
      render js: 'window.location.href="/settings/general";' and return
    end
    
    @general_setting.update(general_params)
    
    respond_to do |format|
      format.js
    end
  end

  def bandwidth
    authorize :admin_settings, :bandwidth?

    @bandwidth_local_setting = Setting.find_by(uid: 'bandwidth_api_local')
    @bandwidth_tf_setting = Setting.find_by(uid: 'bandwidth_api_tf')
  end
  
  def update_bandwidth_settings
    unless request.xhr?
      render js: 'window.location.href="/settings/bandwidth";' and return  
    end

    authorize :admin_settings, :update_bandwidth_settings?

    @bandwidth_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @bandwidth_setting.blank?
      render js: 'window.location.href="/settings/bandwidth";' and return
    end
    
    @bandwidth_setting.update(bandwidth_params)
    
    respond_to do |format|
      format.js
    end
  end

  def invoices
    authorize :admin_settings, :invoices?

    @invoice_settings = Setting.find_by(uid: 'invoices')
  end
  
  def update_invoice_settings
    unless request.xhr?
      render js: 'window.location.href="/settings/invoices";' and return  
    end

    authorize :admin_settings, :update_invoice_settings?

    @invoice_settings = Setting.find_by(uid: params[:setting][:uid])
    
    if @invoice_settings.blank?
      render js: 'window.location.href="/settings/invoices";' and return
    end
    
    @invoice_settings.update(invoices_params)
    
    respond_to do |format|
      format.js
    end
  end

  def zendesk
    authorize :admin_settings, :zendesk?

    @zendesk_setting = Setting.find_by(uid: 'zendesk')

    #logger.info 'groups...' + @groups.inspect 

    respond_to do |format|
      format.html
    end
  end

  def refresh_zendesk_assignees
    authorize :admin_settings, :update_zendesk_settings?

    respond_to do |format|
      format.js
    end
  end

  def update_zendesk_settings
    unless request.xhr?
      render js: 'window.location.href="/settings/zendesk";' and return
    end

    authorize :admin_settings, :update_zendesk_settings?

    @zendesk_setting = Setting.find_by(uid: params[:setting][:uid])

    if @zendesk_setting.blank?
      render js: 'window.location.href="/settings/zendesk";' and return
    end

    if 'test' == params[:form][:action]
      @api_error = test_zendesk_api.blank?
    else
      @zendesk_setting.update(zendesk_params)
    end

    respond_to do |format|
      format.js
    end
  end

  def mailer
    authorize :admin_settings, :mailer?

    @mailer_setting = Setting.find_by(uid: 'mailer')

    respond_to do |format|
      format.html
    end
  end

  def update_mailer_settings
    unless request.xhr?
      render js: 'window.location.href="/settings/mailer";' and return
    end

    authorize :admin_settings, :update_mailer_settings?

    @mailer_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @mailer_setting.blank?
      render js: 'window.location.href="/settings/mailer";' and return
    end
    
    @mailer_setting.update(mailer_params)
    
    respond_to do |format|
      format.js
    end
  end

  def otp
    authorize :admin_settings, :otp?

    @otp_setting = Setting.find_by(uid: 'otp')

    respond_to do |format|
      format.html
    end
  end

  def update_otp_settings
    unless request.xhr?
      render js: 'window.location.href="/settings/otp";' and return
    end

    authorize :admin_settings, :update_otp_settings?

    @otp_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @otp_setting.blank?
      render js: 'window.location.href="/settings/otp";' and return
    end
    
    @otp_setting.update(otp_params)

    respond_to do |format|
      format.js
    end
  end

  def payment_gateways
    authorize :admin_settings, :payment_gateways?

    @paypal_setting = Setting.find_by(uid: 'paypal')
    @cc_setting = Setting.find_by(uid: 'cc_payment')
    @finance_setting = Setting.find_by(uid: 'finance')

    respond_to do |format|
      format.html
    end
  end

  def update_payment_settings
    unless request.xhr?
      render js: 'window.location.href="/settings/payment_gateways";' and return
    end

    authorize :admin_settings, :update_payment_settings?

    @payment_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @payment_setting.blank?
      render js: 'window.location.href="/settings/payment_gateways";' and return
    end
    
    @payment_setting.update(payment_gateways_params)
    
    respond_to do |format|
      format.js
    end
  end

  def update_finance_settings
    authorize :admin_settings, :update_finance_settings?

    @finance_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @finance_setting.blank?
      flash[:error] = 'This is an invalid request.'
      redirect_to '/settings/payment_gateways' and return  
    end
    
    @finance_setting.finance_allowed_amounts = finance_params[:finance_allowed_amounts]

    auth_sample = finance_params[:sample_auth_form]

    if auth_sample.present? && auth_sample.is_a?(ActionDispatch::Http::UploadedFile)
      #remove old file if exists
      if @finance_setting.finance_auth_file_name.present?
        File.unlink(Rails.root.join(APP_CONFIG['sample_auth_file_path']).join(@finance_setting.finance_auth_file_name))
      end

      filename = sanitize_filename(auth_sample.original_filename)
      Setting.upload_auth_form(auth_sample, filename)

      @finance_setting.finance_auth_file_name = filename
      @finance_setting.finance_auth_file_content_type = auth_sample.content_type
    end

    respond_to do |format|
      format.html {
        if @finance_setting.save
          flash[:notice] = 'Finance settings have been updated.'          
        else
          flash[:error] = 'The data seems to be invalid. Failed to update the Finance settings.'
        end
        
        redirect_to '/settings/payment_gateways' and return
      }
    end
  end

  def download_auth_sample
    skip_authorization

    @finance_setting = Setting.find_by(uid: 'finance')

    if @finance_setting.finance_auth_file_name.present?
      send_file Rails.root.join(APP_CONFIG['sample_auth_file_path']).join(@finance_setting.finance_auth_file_name), 
              type: @finance_setting.finance_auth_file_content_type, disposition: 'attachment'
    else
      redirect_to '/settings/finance', error: 'Invalid request.'
    end
  end

  def sms
    authorize :admin_settings, :sms?

    @sms_setting = Setting.find_by(uid: 'sms')

    if DidSmsRate.exists?(carrier_id: nil)
      @did_sms = DidSmsRate.where(carrier_id: nil).first
    else
      @did_sms = DidSmsRate.create
    end

    @outbound_sms_setting = Setting.find_by(uid: 'outbound_sms')
    @sms_other_setting = Setting.find_by(uid: 'sms_other')

    respond_to do |format|
      format.html
    end
  end

  def update_sms_settings
    unless request.xhr?
      render :js => 'window.location.href="/settings/sms";' and return
    end

    authorize :admin_settings, :update_sms_settings?

    @sms_setting = Setting.find_by(uid: params[:setting][:uid])

    if @sms_setting.blank?
      render :js => 'window.location.href="/settings/sms";' and return
    end

    if 'test' == params[:form][:action]
      @api_error = test_sms_api.blank?
    else
      @sms_setting.update(sms_api_params)
    end

    respond_to do |format|
      format.js
    end
  end

  def update_outbound_sms_settings
    authorize :admin_settings, :update_sms_settings?

    unless request.xhr?
      render js: 'window.location.href="/settings/outbound_sms";' and return
    end

    @outbound_sms_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @outbound_sms_setting.blank?
      render js: 'window.location.href="/settings/outbound_sms";' and return
    end
    
    @outbound_sms_setting.update(outbound_sms_params)
    
    respond_to do |format|
      format.js
    end
  end

  def update_sms_other_settings
    authorize :admin_settings, :update_sms_settings?

    unless request.xhr?
      render js: 'window.location.href="/settings/sms";' and return
    end

    @sms_other_setting = Setting.find_by(uid: params[:setting][:uid])
    
    if @sms_other_setting.blank?
      render js: 'window.location.href="/settings/sms";' and return
    end
    
    @sms_other_setting.update(sms_other_params)
    
    respond_to do |format|
      format.js
    end
  end

  def export_non_existing
    authorize :admin_settings, :export_non_existing?

    Carrier.delay.sync_non_existing
    User.delay.sync_non_existing

    respond_to do |format|
      format.js
    end
  end

  def export_to_zendesk
    authorize :admin_settings, :export_to_zendesk?

    Carrier.update_all(zendesk_id: nil)
    User.update_all(zendesk_id: nil)

    Carrier.delay.sync_non_existing
    User.delay.sync_non_existing

    respond_to do |format|
      format.js { render action: 'export_non_existing' }
    end
  end

  private
  
  def bandwidth_params
    params.require(:setting).permit(:uid, :bandwidth_url, :bandwidth_username, :bandwidth_password, 
                                    :bandwidth_account, :bandwidth_location, :bandwidth_search_max_numbers)
  end

  def invoices_params
    params.require(:setting).permit(:uid, :invoice_company_name, :invoice_company_address, :invoice_payment_instructions, 
                                    :invoice_email, :invoice_phone, :invoice_announcement, :invoice_default_billing_cycle)
  end

  def zendesk_params
    params.require(:setting).permit(:uid, :zendesk_enable, :zendesk_url, :zendesk_username, :zendesk_password, 
                                    :zendesk_token, :zendesk_auth_method, :zendesk_default_assignee)
  end

  def mailer_params
    params.require(:setting).permit(:uid, :mailer_enable, :mailer_server_address, :mailer_port, :mailer_domain,
                                    :mailer_email, :mailer_username, :mailer_password)
  end

  def otp_params
    params.require(:setting).permit(:uid, :otp_plivo_auth_id, :otp_plivo_auth_token, :otp_plivo_from,
                                    :otp_message, :otp_plivo_postback_url, :otp_plivo_postback_method, 
                                    :otp_twilio_auth_id, :otp_twilio_auth_token, :otp_twilio_from, :otp_twilio_postback_url, 
                                    :otp_sms_enabled, :otp_email_enabled, :otp_provider)
  end

  def payment_gateways_params
    params.require(:setting).permit(:uid, :paypal_enable, :paypal_login, :paypal_password, :paypal_signature, :paypal_deduct_commission,
                                    :cc_enable, :cc_gateway, :cc_epay_source_key, :cc_epay_pin)
  end

  def finance_params
    params.require(:setting).permit(:uid, :finance_allowed_amounts, :sample_auth_form)
  end

  def sms_api_params
    params.require(:setting).permit(:uid, :sms_user_id, :sms_api_token, :sms_api_secret)
  end

  def outbound_sms_params
    params.require(:setting).permit(:uid, :outbound_sms_server_address, :outbound_sms_port, :outbound_sms_domain,
                                    :outbound_sms_email, :outbound_sms_username, :outbound_sms_password,
                                    :outbound_sms_subject, :outbound_sms_body)
  end
    
  def sms_other_params
    params.require(:setting).permit(:uid, :sms_other_max_recipients,
                                    :sms_other_max_message_size)
  end

  def general_params
    params.require(:setting).permit(:uid, :general_tnc)
  end

  def test_zendesk_api
    client = Zendesk.client(
       zendesk_params[:zendesk_url], zendesk_params[:zendesk_username],
       zendesk_params[:zendesk_token], zendesk_params[:zendesk_password],
       zendesk_params[:zendesk_auth_method]
    )
    
    #data = client.tickets(path: 'users/1572517012/tickets/requested').to_a
    #data = client.users(role: 'end-user').to_a
    data = client.users.find(id: 'me')

    if data.blank?
      return false
    else
      #return true
      return data.id
    end
  end

  def test_sms_api
    client = Bandwidth::Client.new(
       user_id: sms_params[:sms_user_id], 
       api_token: sms_params[:sms_api_token],
       api_secret: sms_params[:sms_api_secret]
    )

    begin
      data = Bandwidth::Account.get(client)
    rescue
      data = {}
    end

    data
  end
end
