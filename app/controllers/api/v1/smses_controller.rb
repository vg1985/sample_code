module API
  module V1
    class SmsesController < ApiController
      def test
        render json: {result: 'This is working'}, status: :ok
      end

      def sendon
        authorize :sms_log, :create?
        
        if message_params[:to].blank?
          render json: {error: 'To is empty.'}, status: :unprocessable_entity and return
        end

        if message_params[:text].blank?
          render json: {error: 'Text is empty.'}, status: :unprocessable_entity and return
        end

        text_size = message_params[:text].size
        max_msg_size = Setting.where(uid: 'sms_other').first.sms_other_max_message_size.to_i

        if text_size > max_msg_size || text_size < 1
          render json: {error: 'Text exceeds the maximum limit.'}, status: :unprocessable_entity and return
        end

        did = @carrier.dids.find_by(did: message_params[:from])
        
        if did.blank?
          render json: {error: 'Invalid From DID.'}, status: :unprocessable_entity and return
        end

        recipient = message_params[:to]

        single_sms_length = APP_CONFIG['single_sms_length']
        messages_count = (text_size/single_sms_length.to_f).ceil

        if @carrier.send_sms_credit?(1, messages_count)
          sms_log = @carrier.send_sms(nil, did, recipient, messages_count, message_params[:text], nil)
        else
          render json: { error: 'Credit is exhausted.' }, status: :unprocessable_entity and return
        end

        render json: sms_log.as_json(only: [:message_id, :status, :unit_price, :total_price, :created_at]), status: :ok
      end

      private
      def message_params
        params.permit(:from, :to, :text)
      end
    end
  end
end

