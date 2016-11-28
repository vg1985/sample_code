class Routing < ActiveRecord::Base
  paginates_per 5

  ROUTING_TYPE = ['Static', 'Dynamic']

  ## ASSOCIATIONS ##
  has_many :routing_trunks
  has_many :egress_trunks, through: :routing_trunks, dependent: :destroy
  has_many :ingress_trunks

  ## VALIDATIONS ##
  validates :name, :egress_trunk_ids, :routing_type, presence: true
  validates :routing_type, inclusion: { in: ROUTING_TYPE }
  validates :name, uniqueness: {allow_blank: true}
  
  ## CLASS METHODS ##
  def self.for_select
    self.select("id, name").all.collect do |r|
      [r.name, r.id]
    end
  end

  def self.plans_in_use
  	IngressTrunk.select("DISTINCT(routing_id)").collect(&:routing_id)
  end

  def trunks
  	trunks = self.egress_trunks
  			.select('egress_trunks.id, egress_trunks.name, 
  								egress_trunks.carrier_id, egress_trunks.is_active')
  	if "Static" == self.routing_type
  		trunks = trunks.order('position ASC')
  	else
  		trunks = trunks.joins(:carrier).order('carriers.company_name ASC')
  	end

  	trunks
  end
end
