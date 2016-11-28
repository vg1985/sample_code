class RoutingTrunk < ActiveRecord::Base
	belongs_to :routing
	belongs_to :egress_trunk

	acts_as_list scope: :routing

	#validates :routing, :egress_trunk, presence: true
end
