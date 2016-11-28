class InboundDidsController < ApplicationController
  after_action :verify_authorized, except: [:cities]
  
  def rates
    authorize :inbound_dids, :rates?

    if LocalDidRate.exists?(carrier_id: nil)
      @local_did = LocalDidRate.defaults
    else
      @local_did = LocalDidRate.create
    end
    
    if TollfreeDidRate.exists?(carrier_id: nil)
      @tollfree_did = TollfreeDidRate.where(carrier_id: nil).first
    else
      @tollfree_did = TollfreeDidRate.create
    end

    if DidSmsRate.exists?(carrier_id: nil)
      @did_sms = DidSmsRate.where(carrier_id: nil).first
    else
      @did_sms = DidSmsRate.create
    end
  end
  
  def update_local_rates
    unless request.xhr?
      render :js => "window.location.href='#{rates_inbound_dids_url}';" and return  
    end
    
    authorize :inbound_dids, :update_local_rates?

    @local_did_rate = LocalDidRate.find_by_id(params[:id])
    
    if @local_did_rate.present? 
      @local_did_rate.update_attributes(local_did_rates_param)
    end
    
    respond_to do |format|
      format.js
    end    
  end
  
  def update_tf_rates
    unless request.xhr?
      render :js => "window.location.href='#{rates_inbound_dids_url}';" and return  
    end

    authorize :inbound_dids, :update_tf_rates?
    
    @tf_did_rate = TollfreeDidRate.find_by_id(params[:id])
    
    if @tf_did_rate.present? 
      @tf_did_rate.update_attributes(tollfree_did_rates_param)
    end
    
    respond_to do |format|
      format.js
    end    
  end

  def update_did_sms_rates
    unless request.xhr?
      render :js => "window.location.href='#{rates_inbound_dids_url}';" and return
    end

    authorize :inbound_dids, :update_local_rates?
    
    @did_sms_rate = DidSmsRate.find_by_id(params[:id])
    
    if @did_sms_rate.present?
      @did_sms_rate.update_attributes(did_sms_rates_param)
    end
    
    respond_to do |format|
      format.js
    end
  end

  def manage
    authorize :inbound_dids, :manage?
    @dids = Did.active.all
  end
  
  def purchase
    authorize :inbound_dids, :purchase?

    unless policy(:inbound_dids).select_carrier?
      @local_rates = carrier.apt_local_did_rate
      @tf_rates = carrier.apt_tollfree_did_rate
      @sms_rates = carrier.apt_sms_did_rate
    end
  end
  
  def search_local_numbers
    if !request.xhr? || params[:search].blank?
      render :js => "window.location.href='#{purchase_inbound_dids_url}';" and return  
    end
    
    authorize :inbound_dids, :search_local_numbers?

    if params[:search][:type] == '1'
      @response = Sipsurge::BandwidthInterface.available_numbers('local', {areaCode: params[:search][:area_code]})
    elsif params[:search][:type] == '2'
      @response = Sipsurge::BandwidthInterface.available_numbers('local', {state: params[:search][:state], city: params[:search][:city]})
    else
      render :js => "window.location.href='#{purchase_inbound_dids_url}';" and return  
    end
    @local_page = true
    
    if current_user.is_admin?
      carrier = Carrier.find(params[:search][:carrier])
    elsif current_user.is_carrier?
      carrier = current_user.carrier
    end

    @local_rates = carrier.apt_local_did_rate
    @tf_rates = carrier.apt_tollfree_did_rate
    @sms_rates = carrier.apt_sms_did_rate

    respond_to do |format|
      format.js {render action: 'search_numbers'}
    end
  end
  
  def search_tf_numbers
    if !request.xhr? || params[:search].blank? || params[:search][:wild_card].blank?
      render :js => "window.location.href='#{purchase_inbound_dids_url}';" and return  
    end
    
    authorize :inbound_dids, :search_tf_numbers? 
    @response = Sipsurge::BandwidthInterface.available_numbers('tollfree', {tollFreeWildCardPattern: params[:search][:wild_card]})
    
    @tollfree_page = true

    if current_user.is_admin?
      carrier = Carrier.find(params[:search][:carrier])
    elsif current_user.is_carrier?
      carrier = current_user.carrier
    end

    @local_rates = carrier.apt_local_did_rate
    @tf_rates = carrier.apt_tollfree_did_rate
    @sms_rates = carrier.apt_sms_did_rate
    
    respond_to do |format|
      format.js {render :action => 'search_numbers'}
    end 
  end

  def voice_settings
    unless request.xhr?
      render :js => "window.location.href='#{request.referrer || root_path}';"
    end

    authorize :inbound_dids, :settings? 

    if current_user.is_admin?
      @did = Did.active.find_by(id: params[:id])
    elsif current_user.is_carrier?
      @did = carrier.dids.active.find_by(id: params[:id])
    end

    if @did.present?
      @did_settings = @did.did_voice_settings
    end

    @bulk_settings = false

    respond_to do |format|
      format.html {  render partial: 'voice_settings' }
    end
  end


  def sms_settings
    unless request.xhr?
      render js: "window.location.href='#{request.referrer || root_path}';"
    end

    authorize :inbound_dids, :settings?

    if current_user.is_admin?
      @did = Did.active.find_by(id: params[:id])
      user_carrier = @did.carrier
    elsif current_user.is_carrier?
      user_carrier = carrier
      @did = carrier.dids.active.find_by(id: params[:id])
    end

    if @did.present?
      if @did.did_sms_settings.present?
        @did_setting = @did.did_sms_settings.first
      else
        @did_setting = @did.did_sms_settings.build
      end
    end

    @bulk_settings = false

    @has_credit = true
    unless @did.enable_sms?
      @has_credit = user_carrier.sms_activation_credit?
    end
    
    @sms_rates = user_carrier.apt_sms_did_rate

    respond_to do |format|
      format.html {  render partial: 'sms_settings' }
    end
  end

  def bulk_voice_settings
    unless request.xhr?
      render :js => "window.location.href='#{request.referrer || root_path}';"
    end

    authorize :inbound_dids, :bulk_settings? 

    @bulk_settings = true

    @did_settings = nil

    respond_to do |format|
      format.html {  render partial: 'voice_settings' }
    end
  end

  def bulk_sms_settings
    unless request.xhr?
      render js: "window.location.href='#{request.referrer || root_path}';"
    end

    authorize :inbound_dids, :bulk_settings?

    if current_user.is_admin?
      dids_carrier = Did.active.where(["id IN (?)", params[:dids]]).select('DISTINCT(carrier_id)').first(2)
      @user_carrier = nil

      if(dids_carrier.size == 1)
        @user_carrier = Carrier.find(dids_carrier.first.carrier_id) 
      end

    elsif current_user.is_carrier?
      @user_carrier = carrier
    end

    if @user_carrier.present?
      #get DIDs count in which sms is still not enabled
      dids_count = Did.where(["id IN (?) AND enable_sms = 0", params[:dids]]).count
      
      @has_credit = @user_carrier.sms_activation_credit?(dids_count)
      @sms_rates = @user_carrier.apt_sms_did_rate
    end

    @bulk_settings = true

    @did_setting = DidSmsSetting.new

    respond_to do |format|
      format.html {  render partial: 'sms_settings' }
    end
  end

  def update_voice_settings
    authorize :inbound_dids, :update_settings? 

    unless request.xhr?
      render :js => "window.location.href='#{request.referrer || root_path}';" and return
    end

    if params[:did_settings][:type].size > 3
      render :js => "window.location.href='#{request.referrer || root_path}';" and return
    end

    if params[:did_settings][:type].include?(DidVoiceSetting::CALL_FWDING_DEST_TYPE) && DidVoiceSetting::CALL_FWDING_DEST_TYPE != params[:did_settings][:type].last
      render :js => "window.location.href='#{request.referrer || root_path}';" and return
    end

    if current_user.is_admin?
      @did = Did.active.find_by(id: params[:id])
    elsif current_user.is_carrier?
      @did = carrier.dids.active.find_by(id: params[:id])
    end

    if @did.present?
      @valid_error = false

      settings = params[:did_settings]
      setting_records = Array.new

      settings[:type].size.times do |i|
         setting = DidVoiceSetting.new(did_id: @did.id, dest_type: settings[:type][i], dest_value: settings[:value][i], description: settings[:desc][i])
        
        if policy(:inbound_dids).change_defaults?
          setting.try_timeout = settings[:try_timeout][i]
          setting.pdd_timeout = settings[:pdd_timeout][i]
        else
          setting.try_timeout = DidVoiceSetting::DEFAULT_TRY_TIMEOUT
          setting.pdd_timeout = DidVoiceSetting::DEFAULT_PDD_TIMEOUT
        end

        unless setting.valid?
          logger.info "Error: #{setting.errors.full_messages}"
          @valid_error = true
          break;
        end

        setting_records << setting
      end
      
      unless @valid_error
        @did.did_voice_settings.clear

        setting_records.each do |rec|
          rec.save
        end
      end
    end

    respond_to do |format|
      format.js {render 'update_settings'}
    end
  end

  def update_sms_settings
    authorize :inbound_dids, :update_settings? 

    if current_user.is_admin?
      @did = Did.active.find_by(id: params[:id])
      user_carrier = @did.carrier
    elsif current_user.is_carrier?
      user_carrier = carrier
      @did = carrier.dids.active.find_by(id: params[:id])
    end

    if @did.present? 
      if params[:enable_sms].to_i == 0 || (params[:enable_sms].to_i == 1 && user_carrier.sms_activation_credit?)
        setting = DidSmsSetting.new(did_id: @did.id, dest_type: params[:did_setting][:type], dest_value: params[:did_setting][:value], description: params[:did_setting][:desc])
        
        if setting.valid?
          @did.set_sms_settings(params[:enable_sms].present?, setting, user_carrier, true, current_user.id, request.remote_ip)
        else
          logger.error "Error: #{setting.errors.full_messages}"
        end
      else
        logger.error 'Carrier does not have sms activation credit.'
      end
    end

    respond_to do |format|
      format.html {
        flash[:notice] = 'The SMS setting has been saved.'
          redirect_to (request.referrer || root_path) and return
      }
      format.js {render 'update_settings'}
    end
  end

  def update_bulk_voice_settings
    authorize :inbound_dids, :update_bulk_settings? 

    dids = params[:dids].split(',')

    if !request.xhr? || params[:dids].blank? || params[:dids].split(',').size < 1
      logger.error 'Not a valid request.'
      render :js => "window.location.href='#{request.referrer || root_path}';" and return
    end

    if params[:did_settings][:type].size > 3
      logger.error 'Settings cannot have more than three types.'
      render :js => "window.location.href='#{request.referrer || root_path}';" and return
    end

    if params[:did_settings][:type].include?(DidVoiceSetting::CALL_FWDING_DEST_TYPE) && DidVoiceSetting::CALL_FWDING_DEST_TYPE != params[:did_settings][:type].last
      logger.error 'Invalid sequence of settings detected.'
      render :js => "window.location.href='#{request.referrer || root_path}';" and return
    end

    dids = params[:dids].split(',')

    if policy(:inbound_dids).select_carrier?
      @dids = Did.active.where(id: dids)
    elsif
      @dids = carrier.dids.active.where(id: dids)
    end

    if @dids.present?
      settings = params[:did_settings]

      @dids.each do |did|
        @valid_error = false
        setting_records = Array.new

        settings[:type].size.times do |i|
           setting = DidVoiceSetting.new(did_id: did.id, dest_type: settings[:type][i], dest_value: settings[:value][i], description: settings[:desc][i])

          if policy(:inbound_dids).change_defaults?
            setting.try_timeout = settings[:try_timeout][i]
            setting.pdd_timeout = settings[:pdd_timeout][i]
          else
            setting.try_timeout = DidVoiceSetting::DEFAULT_TRY_TIMEOUT
            setting.pdd_timeout = DidVoiceSetting::DEFAULT_PDD_TIMEOUT
          end

          unless setting.valid?
            logger.info "Error: #{setting.errors.full_messages}"
            @valid_error = true
            break;
          end

          setting_records << setting
        end
        
        unless @valid_error
          did.did_voice_settings.clear

          setting_records.each do |rec|
            rec.save
          end
        end
      end
    end

    respond_to do |format|
      format.js { render action: :update_settings }
    end
  end

  def update_bulk_sms_settings
    authorize :inbound_dids, :update_bulk_settings? 

    dids = params[:dids].split(',')

    #if !request.xhr? || params[:dids].blank? || params[:dids].split(',').size < 1
      #logger.error 'Not a valid request.'
      #render :js => "window.location.href='#{request.referrer || root_path}';" and return
    #end

    dids = params[:dids].split(',')

    if policy(:inbound_dids).select_carrier?
      dids_carrier = Did.active.where(["id IN (?)", dids]).select('DISTINCT(carrier_id)').first(2)
      user_carrier = nil

      if(dids_carrier.size == 1)
        user_carrier = Carrier.find(dids_carrier.first.carrier_id)
      end

      @dids = Did.active.where(id: dids)
    elsif
      @dids = carrier.dids.active.where(id: dids)
      user_carrier = carrier
    end

    #get DIDs count in which sms is still not enabled
    dids_count = Did.active.where(["id IN (?) AND enable_sms = 0", dids]).count

    if @dids.present? && user_carrier.present?
      if params[:enable_sms].to_i == 0 || (params[:enable_sms].to_i == 1 && user_carrier.sms_activation_credit?(dids_count))
        @dids.each do |did|
          setting = DidSmsSetting.new(did_id: did.id, dest_type: params[:did_setting][:type], dest_value: params[:did_setting][:value], description: params[:did_setting][:desc])
                  
          if setting.valid?
            did.set_sms_settings(params[:enable_sms].present?, setting, user_carrier, false)
          else
            logger.info "Error: #{setting.errors.full_messages}"
          end
        end

        if params[:enable_sms].to_i == 1
          user_carrier.charge_sms_activation_monthly(user_carrier.sms_activation_charges(dids_count), user_carrier.sms_monthly_charges(dids_count), 
          @dids.collect(&:did).join(', '), current_user.id, request.remote_ip)
        end
      else
        logger.error 'Carrier does not have sms activation credit.'
      end
    end

    respond_to do |format|
      format.html {
        flash[:notice] = 'The SMS settings have been saved.'
          redirect_to (request.referrer || root_path) and return
      }

      format.js { render action: :update_settings }
    end
  end

  def cities
    if params[:state].blank?
      respond_to do |format|
        format.html { redirect_to  purchase_inbound_dids_url and return }
        format.js { "window.location.href='#{purchase_inbound_dids_url}';" and return   }
      end
    end

    response = CS.cities(params[:state], :us)

    respond_to do |format|
      format.html {  }
      format.js { render :json => response.to_json }
    end

  end
  
  
  private 
  def local_did_rates_param
    params.require(:local_did_rate).permit(:activation, :monthly, :per_minute, :bill_start, :bill_increment)
  end
  
  def tollfree_did_rates_param
    params.require(:tollfree_did_rate).permit(:activation, :monthly, :per_minute, :bill_start, :bill_increment)
  end

  def did_sms_rates_param
    params.require(:did_sms_rate).permit(:activation, :monthly, :inbound, :outbound, :charge_failed)
  end
end
