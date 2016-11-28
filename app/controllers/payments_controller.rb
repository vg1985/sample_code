class PaymentsController < ApplicationController
  after_action :verify_authorized

  before_action :set_unverified_payment, only: [:finalize, :confirm, :revoke]

  def finalize
    skip_authorization

    @payment.update_attribute(:payer_id, params[:PayerID])
  end

  def confirm
    if @payment.ip_address != request.remote_ip 
      redirect_to :payments, error: 'This is an invalid transaction.'
    end

    skip_authorization

    if @payment.payment_type == 'paypal'
      if @payment.paypal_purchase(request.remote_ip)
        flash[:notice] = 'Payment is successfully submitted and is under verification. Please check the status after sometime.'
      else
        flash[:error] = 'Payment was cancelled.'
      end
    end

    if @payment.payment_type == 'credit_card'
      if @payment.credit_card_capture(request.remote_ip)
        flash[:notice] = 'Payment successfully submitted.'
      else
        flash[:error] = 'Payment was cancelled.'
      end
    end

    redirect_to :payments
  end

  def revoke
    skip_authorization

    @payment.destroy
    redirect_to :payments, error: 'Payment transaction has been cancelled.'
  end

  def index
    authorize Payment.new
    set_resources
  end

  def dt_payments_interplay
    authorize Payment.new, :index?
    
    filter_query = {}

    if policy(:payment).select_carrier?
      filter_query[:carrier_id] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?
      filter_query[:status] = params[:columns]['4']['search']['value'] if params[:columns]['4']['search']['value'].present?
      filter_query[:payment_type] = params[:columns]['1']['search']['value'] if params[:columns]['1']['search']['value'].present?.present?
    else
      filter_query[:status] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?
      filter_query[:payment_type] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?.present?
    end
    
    if policy(:payment).select_carrier?
      filter_query[:status] ||= ['pending']
    else
      filter_query[:status] ||= 'All Statuses'
    end

    if filter_query[:status] == 'All Statuses'
      filter_query[:status] = %w(pending accepted declined deleted)
    end

    select_clause = 'payments.id, payments.payment_type, payments.for_date,
                      payments.amount, payments.status, payments.description';

    if policy(:payment).select_carrier?
      select_clause += ' ,carriers.company_name'
      order_by = "#{Payment::DT_ADMIN_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      @payments = Payment.except_charges.where(filter_query).joins(:carrier).select(select_clause).order(order_by).page(params[:page]).per(params[:length])
        
      @data = @payments.collect do |p| 
        actions = [p.id.to_s]
        actions << (%w{pending accepted}.include?(p.status)) ? true : false #show delete button
        actions << (p.status == 'pending' && p.manual_payment?) ? true : false #show accept button

        [ 
          p.company_name, p.payment_type.humanize, 
          p.for_date.in_time_zone(current_user.timezone).to_s(:carrier), 
          p.amount, p.status.humanize, actions
        ]
      end

    else
      order_by = "#{Payment::DT_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      @payments = current_user.carrier.payments.except_charges.where(filter_query).
                  select(select_clause).order(order_by).
                  page(params[:page]).per(params[:length])

      @data = @payments.collect do |p| 
        actions = [p.id.to_s]
        
        [ p.payment_type.humanize, p.for_date.in_time_zone(carrier.timezone).to_s(:carrier),
          p.amount, p.status.humanize, p.description, actions ]
      end
    end

    respond_to do |format|
      format.json
    end
  end

  def show
    @payment = Payment.find_by(id: params[:id])
    
    if @payment.blank?
      redirect_to :payments, error: 'Payment not found.'
    end

    authorize @payment

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def new
    @payment = Payment.new
    params[:credit_card] = {}
    
    authorize @payment

    setup_disabled_pay_options
  end

  def create
    @payment = Payment.new(payment_params)
    @payment.user = current_user

    if policy(:payment).select_carrier?
      @carrier = Carrier.find(payment_params[:carrier_id])
    else
      @carrier = current_user.carrier
      @payment.for_date = Time.now
    end

    @payment.carrier_id = @carrier.id
    @payment.ip_address = request.remote_ip
    @payment.status = 'pending'

    authorize @payment

    if 'charge' == payment_params[:payment_type]
      unless @payment.charge
        flash[:error] = 'Cannot complete transaction. Payment amount exceeds the credit limit.'
        render action: :add_charge and return
      end
    end

    respond_to do |format|
      format.html do
        if @payment.save
          if payment_params[:payment_type] == 'paypal' && current_user.carrier
            redirect_to express_checkout(@payment) and return
          elsif payment_params[:payment_type] == 'credit_card'
            redirect_to credit_card_verify(@payment, credit_card_params) and return
          elsif payment_params[:payment_type] == 'charge'
            flash[:notice] = 'Charges added succesfully.'
            redirect_to charges_payments_path and return
          else
            flash[:notice] = 'Payment awating for approval.'
            redirect_to payments_path and return
          end
        else
          set_cc_choices if current_user.carrier
        end
      end
    end
  end

  def edit
    @payment = Payment.find(params[:id])

    authorize @payment

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def update
    @payment = Payment.find(params[:id])

    authorize @payment

    if @payment.status != 'pending' || (@payment.status == 'pending' && !@payment.manual_payment?)
      if update_payment_params[:amount].present?
        flash[:error] = "Error: Invalid parameters found in request."
        redirect_to request.referrer and return
      end

      if update_payment_params[:transaction_details].present? && !policy(:payment).never_hide_transaction_details?
        flash[:error] = "Error: Invalid parameters found in request."
        redirect_to request.referrer and return
      end
    end

    respond_to do |format|
      if @payment.update(update_payment_params)
        format.html { redirect_to request.referrer, notice: "#{@payment.payment_type == 'charge'? 'Charge' : 'Payment'} was successfully updated." }
        format.json { head :no_content }
      else
        format.html { redirect_to request.referrer, 
          error: "Sorry! #{@payment.payment_type == 'charge'? 'Charge' : 'Payment'} cannot be updated. Please ensure you are posting right parameters." }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  def accept
    @payment = Payment.where(id: params[:id]).first

    if @payment.blank? || @payment.final?
      flash[:error] = "This #{@payment.payment_type == 'charge'? 'Charge' : 'Payment'} cannot be accepted. Request has invalid parameters."
      redirect_to request.referrer and return
    end

    authorize @payment

    flash[:notice] = @payment.approve ? "#{@payment.payment_type == 'charge'? 'Charge' : 'Payment'} accepted." : 'Action was denied.'
    redirect_to request.referrer
  end

  def set_delete
    @payment = Payment.where(id: params[:id]).first

    authorize @payment

    deduct = params[:deduct] == 'true'
    if @payment.set_delete(deduct)
      flash[:notice] = "#{@payment.payment_type == 'charge'? 'Charge' : 'Payment'} has been deleted successfully."
    else
      flash[:error] = "Action was denied."
    end

    redirect_to request.referrer
  end

  def carrier_payment_options
    authorize Payment.new, :carrier_payment_options?

    unless request.xhr?
      render :js => "window.location.href='#{new_payment_path}';" and return  
    end

    @carrier = Carrier.find(params[:id])
    setup_disabled_pay_options

    respond_to do |format|
      format.js
    end
  end

  def add_charge
    @payment = Payment.new(payment_type: 'charge')
    authorize @payment

    respond_to do |format|
      format.html
    end
  end

  def charges
    authorize Payment.new
  end

  def dt_charges_interplay
    authorize Payment.new, :index?
    
    filter_query = {}

    if policy(:payment).select_carrier?
      filter_query[:carrier_id] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?
      filter_query[:status] = params[:columns]['4']['search']['value'] if params[:columns]['4']['search']['value'].present?
    else
      filter_query[:status] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?
      #filter_query[:payment_type] = params[:columns]["0"]["search"]["value"] if params[:columns]["0"]["search"]["value"].present?.present?
    end
    
    filter_query[:status] ||= 'All Statuses'

    if filter_query[:status] == 'All Statuses'
      filter_query[:status] = %w(pending accepted declined deleted)
    end

    select_clause = 'payments.id, payments.payment_type, payments.for_date, 
                    payments.amount, payments.status, payments.description,
                    payments.charge_type';

    if policy(:payment).select_carrier?
      select_clause += ' ,carriers.company_name'
      order_by = "#{Payment::DT_ADMIN_CHARGES_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      @charges = Payment.charges_only.where(filter_query).joins(:carrier).select(select_clause).order(order_by).page(params[:page]).per(params[:length])
        
      @data = @charges.collect do |p|
        actions = [p.id.to_s]
        actions << (%w{pending accepted}.include?(p.status)) ? true : false #show delete button
        actions << (p.status == 'pending' && p.manual_payment?) ? true : false #show accept button

        [
          p.company_name, p.payment_type.titleize, 
          p.for_date.in_time_zone(current_user.timezone).to_s(:carrier),
          p.amount, p.status.humanize, p.description, actions
        ]
      end

    else
      order_by = "#{Payment::DT_CHARGES_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      @charges = current_user.carrier.payments.charges_only.where(filter_query).select(select_clause).order(order_by).page(params[:page]).per(params[:length])

      @data = @charges.collect do |p| 
        actions = [p.id.to_s]
        
        [ 
          p.charge_type.titleize, 
          p.for_date.in_time_zone(carrier.timezone).to_s(:carrier),
          p.amount, p.status.humanize, p.description, actions
        ]
      end
    end

    respond_to do |format|
      format.json
    end
  end

  private
  def credit_card_verify(payment, credit_card_options)
    # Setting up some Payment Options
    carrier = payment.carrier
    options = {}
    options[:ip] = payment.ip_address
    options[:address] = {}
    options[:address][:company] = carrier.company_name
    options[:address][:address1] = carrier.address1
    options[:address][:address2] = carrier.address2
    options[:address][:city] = carrier.city
    options[:address][:state] = carrier.state
    options[:address][:zip] = carrier.zip

    if params[:credit_card][:storage_id] == '-1' && params[:credit_card][:number].present?
      gateway = PaymentGateway.usaepay
      credit_card = ActiveMerchant::Billing::CreditCard.new(credit_card_options)
      credit_card.month = sprintf("%.2i", credit_card.month)[-2..-1]
      credit_card.year = sprintf("%.2i", credit_card.year)[-2..-1]
      
      response = gateway.authorize(payment.amount_to_cents, credit_card, options)
      is_success = response.success?
      error_message = response.message
      authorization = response.authorization
    else
      # This line uses usaepay's own library
      transaction = CreditCard.usaepay_authorize(payment.amount, credit_card_options)
      is_success = transaction.result.downcase == 'approved' && transaction.resultcode == 'A'
      error_message = transaction.error
      authorization = transaction.refnum
    end
    
    if is_success
      description = "#{payment.description } - #{carrier.company_name} - #{credit_card_options[:brand]}."
      payment.update_attributes transaction_token: authorization, description: description
      return finalize_payment_path payment, token: payment.transaction_token
    else
      payment.decline(error_message)
      flash[:error] = "Payment cancelled. #{error_message}"
      return payments_url
    end
  end

  def express_checkout(payment)
    paypal_gateway = PaymentGateway.paypal_express
    response = paypal_gateway.setup_purchase(payment.amount_to_cents,
      ip: payment.ip_address,
      return_url: finalize_payment_url(payment),
      cancel_return_url: revoke_payment_url(payment),
      notify_url: paypal_ipn_backend_index_url,
      currency: 'USD',
      allow_guest_checkout: false,
      order_id: payment.id,
      items: [{name: "CREDIT-PAYMENT-#{payment.id}", description: payment.description, quantity: '1', amount: payment.amount_to_cents}]
    )
    
    if response.success?
      payment.update_attributes(transaction_token: response.token)
      return paypal_gateway.redirect_url_for(response.token)
    else
      payment.decline(response.message)
      flash[:error] = "Payment cancelled. #{response.message}"
      return payments_path
    end
  end

  def set_unverified_payment
    @payment = current_user.payments.where(id: params[:id], transaction_token: params[:token]).first
    
    if @payment.blank?
      redirect_to :payments, error: 'You are not authorized to perform this action.' and return
    end
  end

  def credit_card_params
    if params[:credit_card][:storage_id].present? && params[:credit_card][:storage_id] != '-1' && (current_user.is_carrier? || policy(:payment).carrier_payment_options?)
      params[:credit_card] ||= {}
      
      if policy(:payment).carrier_payment_options?
        user_credit_card = CreditCard.where(storage_id: params[:credit_card][:storage_id]).first
      else
        set_cc_choices
        user_credit_card = @cc_options.where(storage_id: params[:credit_card][:storage_id]).first
      end
      params[:credit_card][:number] = user_credit_card.storage_id
      params[:credit_card][:brand] = user_credit_card.card_type
      params[:credit_card][:address] = user_credit_card.address
      params[:credit_card][:zip_code] = user_credit_card.zip_code
    end

    params.require(:credit_card).permit(:brand, :number, :verification_value, :month, :year, :first_name, :last_name, :address, :zip_code)
  end

  def payment_params
    allowed_params = [
      :amount, :description, :payment_type, :carrier_id, 
      :custom_type, :transaction_details, :charge_type,
      :for_date
    ]
    
    if policy(:payment).add_note?
      allowed_params << :notes
    end
    
    params.require(:payment).permit(allowed_params)
  end

  def update_payment_params
    allowed_params = [:amount, :description, :transaction_details, :custom_type]
    
    if policy(:payment).add_note?
      allowed_params = [:amount, :description, :notes, :transaction_details, :custom_type]
    end

    params.require(:payment).permit(allowed_params)
  end

  def set_resources
    set_cc_choices if current_user.carrier
    @carriers = Carrier.all
  end

  def set_cc_choices
    @cc_options = current_user.carrier.credit_cards.valid_for_transaction
  end

  def setup_disabled_pay_options
    @disabled_payment_options = []

    if current_user.is_carrier?
      @disabled_payment_options << 'paypal' if PaymentGateway.gateway_settings[0].paypal_enable == '1' && !current_user.carrier.allow_paypal?
      @disabled_payment_options << 'credit_card' if PaymentGateway.gateway_settings[1].cc_enable == '1' && !current_user.carrier.allow_cc?
    end

    if @carrier.present? 
      @disabled_payment_options << 'paypal' if PaymentGateway.gateway_settings[0].paypal_enable == '1' && !@carrier.allow_paypal?
      @disabled_payment_options << 'credit_card' if PaymentGateway.gateway_settings[1].cc_enable == '1' && !@carrier.allow_cc?
    end
  end
end
