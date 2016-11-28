class Order < ActiveRecord::Base
	DT_COLS = [:transaction_type, :sipsurge_order_id, :created_at, :status, :did_transaction_type, :dids, :email]
  DT_ADMIN_COLS = [:company_name, :sipsurge_order_id, :created_at, :status, :transaction_type, :did_transaction_type, :dids, :user_name]

	serialize :dids
	serialize :additional_info
	serialize :rate_info

	STATUS_COMPLETE = 1
	STATUS_PENDING = 2
	STATUS_PARTIAL = 3
	STATUS_ERROR = -1
	STATUS_FAILED = 99

	STATUS_NAMES = { 
		STATUS_COMPLETE: 'Completed', 
		STATUS_PENDING: 'Pending', 
		STATUS_PARTIAL: 'Partially Fullfilled', 
		STATUS_FAILED: 'Failed', 
		STATUS_ERROR: 'Error'
	}

	belongs_to :carrier
	belongs_to :user

	scope :purchase_only, ->{ where(transaction_type: 'Purchase') }
	scope :release_only, ->{ where(transaction_type: 'Release') }
	scope :pending_purchase, ->{ where(status: STATUS_PENDING, transaction_type: 'Purchase') }
	scope :pending_release, ->{ where(status: STATUS_PENDING, transaction_type: 'Release') }



	class << self
		def generate_order_id
			max_id = self.maximum(:id) || 999 #(1000 - 1) - Orders start from Autoincrement ID 1000
			Date.today.strftime("%Y%m%d-#{max_id + 1}")
		end

		def execute(carrier, user_id, type, numbers, email, ip_address, order_id = nil)
			response = Sipsurge::BandwidthInterface.order(type, numbers, order_id, "Carrier##{carrier.id}-purchase")

			did_rate = carrier.did_rate_by_type(type)

			order = Order.new(response[:order])
			order.email = email || carrier.user.email
			order.transaction_type = 'Purchase'
			order.did_transaction_type = type
			order.rate_info = { activation: did_rate.activation, monthly: did_rate.monthly, per_minute: did_rate.per_minute, unit_price: carrier.unit_price(type) }
			order.carrier = carrier
			order.user_id = user_id

			if :success == response[:status]
				order.status = Order::STATUS_PENDING
			else
				order.status = Order::STATUS_ERROR
				order.additional_info = {completed_numbers: [], failed_numbers: [], errors: [response[:error]]} 
			end

			ActiveRecord::Base.transaction do
				order.save

				if Order::STATUS_PENDING == order.status
					carrier.charge_did_activation_monthly(carrier.did_activation_charges(type, numbers.size), carrier.did_monthly_charges(type, numbers.size),
						numbers.join(', '), user_id, ip_address)
				end
			end

			order
		end

		def release(user, type, numbers, reason)
			response = Sipsurge::BandwidthInterface.release(type, numbers, "User##{user.name}-release")

			order = Order.new(response[:order])
			order.sipsurge_order_id = Order.generate_order_id
			order.email = user.email
			order.transaction_type = 'Release'
			order.did_transaction_type = type
			order.rate_info = {}
			order.carrier = user.is_admin? ? nil : user.carrier
			order.user_id = user.id
			order.additional_info = {'reason': reason}

			if :success == response[:status]
				order.status = Order::STATUS_PENDING
			else
				order.status = Order::STATUS_ERROR
			end

			order.save

			if Order::STATUS_PENDING == order.status 
				if user.is_admin?
					Did.where(did: numbers).update_all(status: Did::STATUS_AGING)
				else
					user.carrier.dids.where(did: numbers).update_all(status: Did::STATUS_AGING)
				end
				
			end

			order
		end
	end

	def dids_count
		if self.dids.is_a?(Array)
			return self.dids.size
		else
			return 1
		end
	end
	
end
