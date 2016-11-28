class CarrierSettingsController < ApplicationController

  after_action :verify_authorized

  def credit_cards
    authorize :carrier_settings, :credit_cards?

    @auto_recharge_setting = CarrierSetting.for(current_user.carrier, 'auto_recharge')
    @low_credit_notification_setting = CarrierSetting.for(current_user.carrier, 'low_credit_notification')
  end
  
  def update_credit_card_settings
    unless request.xhr?
      render :js => "window.location.href='/carrier/settings/credit_cards';" and return  
    end

    authorize :carrier_settings, :update_credit_card_settings?

    @credit_card_setting = CarrierSetting.find_by(carrier_id: current_user.carrier.id, uid: params[:carrier_setting][:uid])
    
    if @credit_card_setting.blank?
      render :js => "window.location.href='/carrier/settings/credit_cards';" and return  
    end
    
    @validation_error = false

    if CarrierSetting.valid_for_credit_card?(current_user.carrier, credit_cards_params)
      @credit_card_setting.update(credit_cards_params)
    else
      @validation_error = true
    end
    
    respond_to do |format|
      format.js
    end
  end

  private
  
  def credit_cards_params
    params.require(:carrier_setting).permit(:uid, :auto_recharge_enable, :auto_recharge_storage_id, :auto_recharge_balance_threshold, 
                                    :auto_recharge_recharge_amount, :lc_notification_enable, :lc_notification_balance_threshold)
  end
end
