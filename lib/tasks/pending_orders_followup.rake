namespace :background do
	desc "Follow Bandwidth for the pending orders status"
  task :pending_orders_followup => :environment do
    logger = Logger.new(File.join(Rails.root, "log", "pending_orders_followup.log"))
    start_time = Time.now
    logger.info "Start Time....#{start_time}"

    #task start
    #Get Purchase Orders status
  	Order.pending_purchase.each do |order|
      logger.info "Processing purchased order.....#{order.id}"

  		response = Bandwidth.order_followup(order)

      case response["OrderStatus"]
  		when "COMPLETE"
  			order.status = Order::STATUS_COMPLETE

  		when "PARTIAL"
  			order.status = Order::STATUS_PARTIAL
        
      when "FAILED"
        order.status = Order::STATUS_FAILED

  		when "Exception"
        order.status = Order::STATUS_ERROR
      end

      order.provider_status = response["OrderStatus"]
      order.additional_info = Bandwidth.order_additional_info(response)
  		

      ActiveRecord::Base.transaction do
        order.save

        carrier = order.carrier

        order.additional_info[:completed_numbers].each do |number|
          carrier.ungrouped_group.dids.create(carrier: carrier, did: number, activation: order.rate_info[:activation], monthly: order.rate_info[:monthly], bill_start: order.created_at.to_date, status: Did::STATUS_ACTIVE, transaction_type: order.did_transaction_type, vendor: "bandwidth")
        end

        #refund failed numbers 
        if response["FailedQuantity"].present? && response["FailedQuantity"].to_i > 0
          refund = carrier.unit_price(order.did_transaction_type) * response["FailedQuantity"].to_i
          carrier.increment!(:ingress_credit, refund)
        end
      end
  	end

    #Get Purchase Orders status
    Order.pending_release.each do |order|
      logger.info "Processing released order.....#{order.id}"

      response = Bandwidth.release_followup(order)
      case response["OrderStatus"]
      when "COMPLETE"
        order.status = Order::STATUS_COMPLETE

      when "PARTIAL"
        order.status = Order::STATUS_PARTIAL
        
      when "FAILED"
        order.status = Order::STATUS_FAILED

      when "Exception"
        order.status = Order::STATUS_ERROR
      end

      order.provider_status = response["OrderStatus"]
      response["reason"] = order.additional_info["reason"]
      order.additional_info = response

      ActiveRecord::Base.transaction do
        order.save
        carrier = order.carrier

        #restore dids for incomplete/partial/failed/error orders
        if [Order::STATUS_COMPLETE, Order::STATUS_PARTIAL].include?(order.status)
          dids = response["DisconnectedTelephoneNumberList"]["TelephoneNumber"]
          
          unless dids.is_a?(Array)
            dids = [dids]            
          end

          dids.each do |did|
            if carrier.blank?
              Did.find_by(did: did).update_attribute('status', Did::STATUS_DISCONNECTED)
            else
              carrier.dids.find_by(did: did).update_attribute('status', Did::STATUS_DISCONNECTED)
            end
          end
        end
      end
    end

    #task end
    end_time = Time.now
    logger.info "End Time....#{end_time}"
    logger.info "Executiion Time ...#{end_time - start_time} seconds"
  end

  task :onetime_db_update => :environment do
    Did.all.each do |did|
      group = did.did_group
      did.update_attribute(:carrier_id, group.carrier.id)
    end
  end
end