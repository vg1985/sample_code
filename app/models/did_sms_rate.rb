class DidSmsRate < ActiveRecord::Base
	belongs_to :carrier

	validates :activation, :monthly, :outbound, :inbound, presence: true, on: :create, allow_nil: true
	#validates :bill_start, :bill_increment, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }, allow_nil: true
	validates :activation, :monthly, :outbound, :inbound, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99.9999 }, allow_nil: true
	
	def self.defaults
	  @defaults = self.where(carrier_id: nil).first
	end
	
	def to_arr
	  [self.activation, self.monthly, self.outbound, self.inbound, self.charge_failed]
	end
end
