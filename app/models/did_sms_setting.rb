class DidSmsSetting < ActiveRecord::Base
	FWDTO_DEST_TYPE = 1
	EMAIL_DEST_TYPE = 2
	API_DEST_TYPE = 3

	DEST_TYPES = [FWDTO_DEST_TYPE, EMAIL_DEST_TYPE, API_DEST_TYPE]

	belongs_to :did

	#validates :dest_type, :dest_value, presence: true
	validates :dest_type, inclusion: { in: DEST_TYPES }, allow_blank: true
	validates :dest_value, format: { with: URI.regexp }, allow_blank: true, if: Proc.new { |s| API_DEST_TYPE == s.dest_type}
	validates :dest_value, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}, allow_blank: true, if: Proc.new { |s| EMAIL_DEST_TYPE == s.dest_type  }
	validates :dest_value, numericality: { only_integer: true }, allow_blank: true, if: Proc.new { |s| FWDTO_DEST_TYPE == s.dest_type }

	def self.select_options
		{'Forward To': FWDTO_DEST_TYPE, 'Email To': EMAIL_DEST_TYPE, 'Post To URL': API_DEST_TYPE}
	end
end
