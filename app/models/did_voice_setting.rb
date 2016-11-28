class DidVoiceSetting < ActiveRecord::Base
	self.table_name = 'did_settings'

	CALL_FWDING_DEST_TYPE = 1
	TRUNK_DEST_TYPE = 2
	IP_DOMAIN_DEST_TYPE = 3

	DEFAULT_PDD_TIMEOUT = 6
	DEFAULT_TRY_TIMEOUT = 3

	DEST_TYPES = [CALL_FWDING_DEST_TYPE, TRUNK_DEST_TYPE, IP_DOMAIN_DEST_TYPE]

	belongs_to :did

	validates :dest_type, :dest_value, :try_timeout, :pdd_timeout, presence: true
	validates :try_timeout, :pdd_timeout, numericality: { only_integer: true }, inclusion: { in: 3..60 }
	validates :dest_value, length: { in: 3..200 }, if: Proc.new { |s| CALL_FWDING_DEST_TYPE == s.dest_type }
	validates :dest_value, format: { with: /\A[a-z0-9\.\-]+\z/i }, if: Proc.new { |s| IP_DOMAIN_DEST_TYPE == s.dest_type  }
	validates :dest_value, numericality: { only_integer: true }, if: Proc.new { |s| TRUNK_DEST_TYPE == s.dest_type }

end
