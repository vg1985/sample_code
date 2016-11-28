class CarriersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:register, :check_company, 
    :check_email, :check_account_code, :check_username, :do_register,
    :unreg_verify_otp, :check_unique_contacts, :check_mobile
  ]

  after_action :verify_authorized

  before_action :load_carrier, except: [:index, :dt_carriers_interplay, 
    :update_bulk_status, :new, :create, :check_company, :check_email, 
    :check_account_code, :check_username, :register, :do_register, 
    :contact_options, :unreg_verify_otp, :check_unique_contacts,
    :check_mobile
  ]

  def index
    authorize Carrier.new
  end

  def dt_carriers_interplay
    authorize Carrier.new, :index?
    
    filter_query = {}
    
    if policy(:carrier).select_carrier?
      allowed_carriers = current_user.allowed_carriers

      unless allowed_carriers.include?('-10')
        filter_query = ['carriers.id IN (?)', allowed_carriers]
      end
    end

    #select_clause = 'carriers.id, carriers.company_name, users.id AS user_id, users.email AS user_email,
    #                 carriers.ingress_credit, carriers.egress_credit, carriers.is_active'
    select_clause = 'carriers.id, carriers.company_name, carriers.account_code, users.id AS user_id,
                     users.email AS user_email, users.username, carriers.is_active'

    search_filter = ['carriers.company_name LIKE :search OR
                      users.email LIKE :search OR
                      carriers.account_code LIKE :search OR
                      users.username LIKE :search',
                      {search: "%#{params['search']['value']}%"}]

    order_by = "#{Carrier::DT_ADMIN_COLS[params[:order]['0'][:column].to_i - 1]} #{params[:order]['0'][:dir]}"
    
    @carriers = Carrier.where(filter_query).joins([:user]).select(select_clause).order(order_by)

    if params['search']['value'].present?
      @carriers = @carriers.where(search_filter)
    end

    @carriers = @carriers.page(params[:page]).per(params[:length])
      
    @data = @carriers.collect do |c|
      [c.id, c.username, c.account_code, ERB::Util.html_escape(c.company_name),
        c.user_email, c.is_active?,
        #c.ingress_trunks.count, c.egress_trunks.count, c.ingress_credit, c.egress_credit
        [
          [ 
            policy(:carrier).list_enable?, 
            policy(:carrier).list_disable?
          ], 
          policy(:carrier).list_edit?,
          policy(:carrier).list_destroy?,
          [policy(:carrier).list_masquerade?, c.user.id]
        ]
      ]
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    @carrier = Carrier.new

    authorize @carrier
    
    @carrier.generate_account_code
    
    @ldr_defaults = LocalDidRate.defaults
    @tfdr_defaults = TollfreeDidRate.defaults
    @dsr_defaults = DidSmsRate.defaults
    @carrier.build_local_did_rate
    @carrier.build_tollfree_did_rate
    @carrier.build_did_sms_rate
  end

  def register
    skip_authorization

    @carrier = Carrier.new
    #@carrier.generate_account_code

    respond_to do |format|
      format.html { render layout: 'application' }
    end
  end

  def do_register
    skip_authorization

    @carrier = Carrier.new(registration_params)
    @carrier.user.internal = false

    if verify_recaptcha
      if @carrier.save
        flash[:notice] = 'You have been successfully registered as carrier. You can now login here.'
      else
        logger.error "Error: #{@carrier.errors.full_messages.to_s}"
        flash[:error] = 'Carrier could not be saved due to error.'
      end

      redirect_to user_session_path and return
    else
      flash[:error] = 'Invalid Captcha. Please try again.'
      render action: :register, layout: 'application'
    end
  end

  def edit_profile
    authorize @carrier

    respond_to do |format|
      format.html
    end
  end

  def update_profile
    authorize @carrier

    if params[:otpid].present? && params[:otpcode].present?
     if Otp.verify(current_user.id, params[:otpid], params[:otpcode], 'carrier_update')
        if(@carrier.update_attributes(update_profile_params))
          flash[:notice] = 'Your profile has been successfully updated. Please note that if you 
                          have requested the email change then the confirmation request is sent to your new email ID.'
        else
          logger.error "Error: #{@carrier.errors.full_messages.to_s}"
          flash[:error] = 'Your profile could not be saved due to error.'
        end
      else
        flash[:error] = 'Cannot perform update operation. The OTP is invalid or has expired.'
      end
    else
      old_contacts_count = @carrier.contacts.size
      @carrier.attributes = update_profile_params
      if @carrier.update_otp_auth_required?(old_contacts_count)
        flash[:error] = 'The action could not be performed. This action requires OTP authorization.'
      else
        if(@carrier.save)
          flash[:notice] = 'Your profile has been successfully updated.'
        else
          logger.error "Error: #{@carrier.errors.full_messages.to_s}"
          flash[:error] = 'Your profile could not be saved due to error.'
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to root_url }
    end
  end

  def create
    @carrier = Carrier.new(carrier_params)
    
    authorize @carrier

    @carrier.user.internal = false

    if @carrier.save
      flash[:notice] = 'Carrier created successfully.'
    else
      logger.error "Error: #{@carrier.errors.full_messages.to_s}"
      flash[:error] = 'Carrier could not be saved due to error.'
    end
    
    redirect_to carriers_path
  end

  def update
    authorize @carrier

    if(@carrier.update_attributes(carrier_params))
      if current_user.internal?
        flash[:notice] = 'Carrier profile has been successfully updated. Please note that if you 
                            have requested the email change then the confirmation request is sent to carrier\'s new email ID.'
      else
        flash[:notice] = 'Your profile has been successfully updated. Please note that if you 
                            have requested the email change then the confirmation request is sent to your new email ID.'
      end
      
    else
      logger.info "Error: #{@carrier.errors.full_messages.to_s}"
      flash[:error] = 'Carrier could not be saved due to error.'
    end
    
    redirect_to carriers_path
  end

  def edit
    authorize @carrier

    @ldr_defaults = LocalDidRate.defaults
    @tfdr_defaults = TollfreeDidRate.defaults
    @dsr_defaults = DidSmsRate.defaults
    
    @carrier_ldr = @carrier.local_did_rate
    @carrier_tfdr = @carrier.tollfree_did_rate
    @carrier_dsr = @carrier.did_sms_rate
    
    @carrier_po = [@carrier.allow_cc]
    
    @carrier.build_local_did_rate if @carrier_ldr.blank?
          
    @carrier.build_tollfree_did_rate if @carrier_tfdr.blank?

    @carrier.build_did_sms_rate if @carrier_dsr.blank?
  end
  
  def enable
    authorize @carrier

    @carrier.update_attribute(:is_active, true)
    @success_msg = 'Carrier has been enabled updated successfully.'
    
    render :update_status
  end
  
  def disable
    authorize @carrier

    @carrier.update_attribute(:is_active, false)
    @success_msg = 'Carrier has been disabled updated successfully.'

    render :update_status
  end

  def update_bulk_status
    authorize IngressTrunk.new

    @carriers = Carrier.where(id: params[:carrier_ids])
    @carriers.update_all(is_active: params[:enable].present? ? true : false)
    @success_msg = 'Carriers status have been updated successfully.'

    render :update_status
  end

  def destroy
    authorize @carrier
    @carrier.destroy
  end

  def egress_trunks
    @egress_trunks = @carrier.egress_trunks
  end

  def billing_rates
    authorize :inbound_dids, :select_carrier?

    carrier = Carrier.find(params[:id])
    @local_rates = carrier.apt_local_did_rate
    @tf_rates = carrier.apt_tollfree_did_rate
    @sms_rates = carrier.apt_sms_did_rate

    respond_to do |format|
      format.html { render partial: 'inbound_dids/billing_rates_modal' }
    end
  end
  
  def check_company
    skip_authorization
    @carrier = Carrier.where(company_name: params[:carrier][:company_name]).limit(1)
    
    if params[:carrier_id].to_i > 0
      @carrier = @carrier.where(['id != ?', params[:carrier_id]])
    end
    
    respond_to do |format|
      format.json { render :json => @carrier.blank? }
    end
  end
  
  def check_email
    skip_authorization

    user = User.where(email: params[:carrier][:user_attributes][:email]).limit(1)
    
    if params[:user_id].to_i > 0
      user = user.where(['id != ?', params[:user_id]])
    end
    
    contact = Contact.find_by(email: params[:carrier][:user_attributes][:email])
    respond_to do |format|
      format.json { render json: user.blank? && contact.blank? }
    end
  end

  def check_mobile
    skip_authorization
    mobile = "#{params[:dialcode]}#{params[:carrier][:mobile]}".gsub(/[()\ -]/, '')
    carrier = Carrier
              .where(["REPLACE( REPLACE( REPLACE( REPLACE(  mobile,  '-',  '' ) ,  '(',  '' ) ,  ')',  '' ) ,  ' ',  '' ) = ?", mobile])
              .limit(1)
    
    if params[:carrier_id].to_i > 0
      carrier = carrier.where(['id != ?', params[:carrier_id]])
    end
    
    contact = Contact
              .where(["REPLACE( REPLACE( REPLACE( REPLACE(  mobile,  '-',  '' ) ,  '(',  '' ) ,  ')',  '' ) ,  ' ',  '' ) = ?", mobile])
              .limit(1)
    respond_to do |format|
      format.json { render json: carrier.blank? && contact.blank? }
    end
  end

  def check_unique_contacts
    skip_authorization

    if params[:emails].present? ||
      params[:mobiles].present?

      if user_signed_in?
        if current_user.is_admin? &&
          params[:carrier_id].present?

          carrier = Carrier.find(params[:carrier_id])
        else
          carrier = current_user.carrier
        end
      end
    end

    if params[:emails].present?
      emails = params[:emails].split(',').reject(&:empty?)

      if params[:new].blank?
        emails -= carrier.contacts.collect {|c| c.email}
      end

      dup_emails = []

      if emails.present?
        dup_emails = Contact.where(['email IN (?)', emails]).select('email').all.collect(&:email) +
                      User.where(['email IN (?)', emails]).select('email').all.collect(&:email)
      end
      
      if dup_emails.size > 0
        respond_to do |format|
          format.json { render json: {found: true, emails: dup_emails.join(','), mobiles: [] } and return }
        end
      end
    end

    if params[:mobiles].present?
      mobiles = params[:mobiles].split(',').reject(&:empty?)

      if params[:new].blank?
        mobiles -= carrier.contacts.collect {|c| c.mobile.gsub(/[()\ -]/, '')}
      end

      dup_mobiles = []

      if mobiles.present?
        dup_mobiles = Contact.select('mobile')
              .where(["REPLACE( REPLACE( REPLACE( REPLACE(  mobile,  '-',  '' ) ,  '(',  '' ) ,  ')',  '' ) ,  ' ',  '' ) IN (?)", mobiles])
              .all.collect(&:mobile) + Carrier.select('mobile')
              .where(["REPLACE( REPLACE( REPLACE( REPLACE(  mobile,  '-',  '' ) ,  '(',  '' ) ,  ')',  '' ) ,  ' ',  '' ) IN (?)", mobiles])
              .all.collect(&:mobile)
      end

      if dup_mobiles.size > 0
        respond_to do |format|
          format.json { render json: { found: true, emails: [], mobiles: dup_mobiles.join(',') } and return }
        end
      end
    end

    respond_to do |format|
      format.json { render json: {found: false} }
    end
  end


  def check_username
    skip_authorization

    @user = User.where(username: params[:carrier][:user_attributes][:username]).limit(1)
    
    if params[:user_id].to_i > 0
      @user = @user.where(['id != ?', params[:user_id]])
    end
    
    respond_to do |format|
      format.json { render json: @user.blank? }
    end
  end
  
  def check_account_code
    skip_authorization

    @carrier = Carrier.where(account_code: params[:carrier][:account_code]).limit(1)
    
    if params[:carrier_id].to_i > 0
      @carrier = @carrier.where(['id != ?', params[:carrier_id]])
    end
    
    respond_to do |format|
      format.json { render :json => @carrier.blank? }
    end
  end

  def refresh_token
    authorize @carrier

    respond_to do |format|
      format.js { render json: @carrier.create_api_token }
    end
  end
  
  def edit_password
    authorize @carrier
    
    if @carrier.user.send_reset_password_instructions
      flash[:notice] = 'Change password instructions has been sent to your email registered with us.'
    else
      flash[:error] = 'OOPS! Please try after some time.'
    end  
    
    redirect_to edit_profile_carrier_path(current_user.carrier) and return
  end

  def contact_options
    skip_authorization

    allowed_carriers = current_user.allowed_carriers

    if allowed_carriers.include?('-10')
      @carrier = Carrier.find_by_zendesk_id(params[:id])
    else 
      @carrier = Carrier.where(['carriers.id IN (?) AND zendesk_id = ?', allowed_carriers, params[:id]]).first
    end

    if @carrier.present?
      @emails = @carrier.emails_for_support
      @phones = @carrier.phones_for_support
    else
      respond_to do |format|
        format.js { render 'shared/not_found' and return }
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def unreg_verify_otp
    skip_authorization

    if params[:otp_code].blank? ||
      params[:otp_id].blank?

      render json: {verified: false} and return
    end

    verified = Otp.verify(-1, params[:otp_id], params[:otp_code], params[:a])

    if verified
      session["verified_#{params[:element]}"] = session["#{params[:element]}_to_verify"]
      session["#{params[:element]}_to_verify"] = nil

      render json: {verified: true} and return
    else
      render json: {verified: false} and return
    end
  end

  private
  def carrier_params
    params[:carrier][:local_did_rate_attributes] = nil_did_rates.merge(params[:carrier][:local_did_rate_attributes]) if params[:carrier][:local_did_rate_attributes].present? 
    params[:carrier][:tollfree_did_rate_attributes] = nil_did_rates.merge(params[:carrier][:tollfree_did_rate_attributes]) if params[:carrier][:tollfree_did_rate_attributes].present?
    params[:carrier][:did_sms_rate_attributes] = nil_did_sms_rates.merge(params[:carrier][:did_sms_rate_attributes]) if params[:carrier][:did_sms_rate_attributes].present? 
    post_params = params[:carrier].permit(:id, :account_code, :company_name, :address1, :address2, :city, :state, :zip,
                            :country, :phone1, :phone2, :mobile, :timezone, :user_id, :allow_cc, :allow_paypal, :allow_paypal_ipn, :max_cost, 
                            :credit_limit, :egress_credit, :ingress_credit, :call_limit, :is_active, :cps_limit, :type_paid, :billing_cycle, 
                            :wireless_block_cost, :reseller_id, :reseller_commission_rate,  :sell_ratesheet_id, :invoice_period, contacts_attributes: contacts_attributes, 
                            local_did_rate_attributes: did_rate_attributes, tollfree_did_rate_attributes: did_rate_attributes, user_attributes: user_attributes,
                            did_sms_rate_attributes: sms_attributes)
    post_params[:phone1] = "#{params[:carrier][:phone1_code]} #{post_params[:phone1]}"
    post_params[:phone2] = "#{params[:carrier][:phone2_code]} #{post_params[:phone2]}"
    post_params[:mobile] = "#{params[:carrier][:mobile_code]} #{post_params[:mobile]}"
    post_params
  end

  def registration_params
    post_params = params[:carrier].permit(:account_code, :company_name, :address1, :address2, :city, :state, :zip,
                            :country, :phone1, :phone2, :mobile, :timezone, :user_id, 
                            contacts_attributes: contacts_attributes, user_attributes: user_attributes)
    
    post_params[:phone1] = "#{params[:carrier][:phone1_code]} #{post_params[:phone1]}"
    post_params[:phone2] = "#{params[:carrier][:phone2_code]} #{post_params[:phone2]}"
    #post_params[:mobile] = "#{params[:carrier][:mobile_code]} #{post_params[:mobile]}"
    post_params[:mobile] = session['verified_mobile']
    post_params[:user_attributes][:email] = session['verified_email']
    post_params
  end

  def update_profile_params
    post_params = params[:carrier].permit(:id, :phone1, :phone2, :mobile, :timezone, :user_id,
                  contacts_attributes: contacts_attributes, user_attributes: [:id, :email])
    post_params[:phone1] = "#{params[:carrier][:phone1_code]} #{post_params[:phone1]}"
    post_params[:phone2] = "#{params[:carrier][:phone2_code]} #{post_params[:phone2]}"
    post_params[:mobile] = "#{params[:carrier][:mobile_code]} #{post_params[:mobile]}"
    post_params
  end
  
  def nil_did_rates
    {activation: nil, monthly: nil, per_minute: nil, bill_start: nil, bill_increment: nil}
  end

  def nil_did_sms_rates
    {activation: nil, monthly: nil, outbound: nil, inbound: nil}
  end
  
  def contacts_attributes
    [:id, :name, :email, :phone, :phone_code, :mobile, :mobile_code, :contact_type, :carrier_id, :description, :_destroy]
  end
  
  def did_rate_attributes
    [:id, :activation, :monthly, :per_minute, :bill_start, :bill_increment]
  end
  
  def user_attributes
    [:id, :username, :name, :email, :password, :password_confirmation]
  end

  def sms_attributes
    [:id, :activation, :monthly, :inbound, :outbound, :charge_failed]
  end
  
  def load_carrier
    @carrier = Carrier.find_by_id(params[:id])
    #raise @carrier.inspect
    unless @carrier
      flash[:error] = 'Carrier not found'
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render 'shared/not_found' }
      end
    end
  end

  def update_status
    params[:enable].present? ? true : false
  end

end
