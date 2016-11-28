class BackendController < ApplicationController
  
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  include OffsitePayments::Integrations

  def paypal_ipn
=begin
{"mc_gross"=>"1.00", "invoice"=>"26", "protection_eligibility"=>"Eligible", "address_status"=>"unconfirmed", "payer_id"=>"H8AA92RKQ22N4", "tax"=>"0.00", "address_street"=>"Flat no. 507 Wing A Raheja Residency\r\nFilm City Road, Goregaon East", "payment_date"=>"02:10:04 Aug 05, 2015 PDT", "payment_status"=>"Completed", "charset"=>"windows-1252", "address_zip"=>"400097", "first_name"=>"test", "mc_fee"=>"0.34", "address_country_code"=>"IN", "address_name"=>"test buyer", "notify_version"=>"3.8", "custom"=>"", "payer_status"=>"verified", "address_country"=>"India", "address_city"=>"Mumbai", "quantity"=>"1", "verify_sign"=>"AZuRXZRkuk7frhfirfxxTkj0BDJGAiNIldMgKQjBPCFQxMxaW3GtaxiF", "payer_email"=>"aleeninfosolutions-buyer@gmail.com", "txn_id"=>"9D884359V0610542K", "payment_type"=>"instant", "last_name"=>"buyer", "address_state"=>"Maharashtra", "receiver_email"=>"vineet@voipessential.com", "payment_fee"=>"0.34", "receiver_id"=>"94YUDLHY7BKDN", "txn_type"=>"express_checkout", "item_name"=>"", "mc_currency"=>"USD", "item_number"=>"", "residence_country"=>"IN", "test_ipn"=>"1", "handling_amount"=>"0.00", "transaction_subject"=>"", "payment_gross"=>"1.00", "shipping"=>"0.00", "ipn_track_id"=>"6adb14bd31f1e"}
=end
    notify = Paypal::Notification.new(request.raw_post)

    if notify.masspay?
      masspay_items = notify.items
    end

    if notify.acknowledge
      begin
        payment = Payment.find(notify.invoice)
        
        if notify.complete? && payment.amount == notify.gross.to_f && 
          payment.payer_id == params[:payer_id] && notify.currency == 'USD'

          if PaymentGateway.paypal_deduct_commission?
            payment.amount -= notify.fee.to_f
          end

          payment.transaction_details = notify.transaction_id
          payment.approved_at = Time.now
          payment.approve

          logger.info 'Transaction is complete'
        else
          logger.error('Failed to verify Paypal\'s notification, please investigate')
        end

      rescue => e
        payment.decline(e.message)
        raise
      end
    end

    render nothing: true
  end

  def receive_sms
    #Parameters: {"to"=>"+15102980799", "time"=>"2016-01-04T07:36:53Z", "text"=>"55555", "direction"=>"in", "applicationId"=>"a-zezsjibk3zkp7z2epaa7bmy", "state"=>"received", "from"=>"+16784214747", "eventType"=>"sms", "messageId"=>"m-l2wt3offp3yqrgwv6hekf6i", "messageUri"=>"https://api.catapult.inetwork.com/v1/users/u-5rfnnm54fbtq4p3t7mzhx5i/messages/m-l2wt3offp3yqrgwv6hekf6i"}
    if params[:applicationId] == 'a-zezsjibk3zkp7z2epaa7bmy' &&
       params[:eventType] == 'sms' &&
       params[:state] == 'received' &&
       params[:to].present? &&
       params[:from].present?

       did = Did.find_by(did: params[:to][2..-1])
       if did.present?

        carrier = did.carrier
        # @TODO: check if carrier has enough credit
        carrier.recieve_sms(did, params[:from], params[:text], params[:messageId])
       end
    end  

    render nothing: true, status: :ok
  end

  def plivo_status
    plog = LogOtp.find_by(uuid: params['MessageUUID'])

    if plog.present?
      plog.update({
        puuid: params['ParentMessageUUID'],
        destination: params['To'],
        source: params['From'],
        units: params['Units'],
        total_amount: params['TotalAmount'],
        total_rate: params['TotalRate'],
        status: params['Status']
      })
    end

    render nothing: true, status: :ok
  end

  def twilio_status
    plog = LogOtp.find_by(uuid: params['MessageSid'])

    if plog.present?
      plog.update({
        puuid: params['AccountSid'],
        status: params['MessageStatus']
      })
    end

    render nothing: true, status: :ok
  end
end