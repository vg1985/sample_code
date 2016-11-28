class EgressTrunk < ActiveRecord::Base
  ## CONSTANTS ##
  ROUTING_STRATEGIES = {0 => 'Round Robin', 1 => 'Top Down'}
  DT_ADMIN_COLS = [:name, :company_name, :rate_sheet_name]

   ## ASSOCIATIONS ##
  belongs_to :carrier
  belongs_to :rate_sheet
  has_many :hosts, as: :trunk, dependent: :destroy

  scope :active, -> { where(is_active: true) }

  ## NESTED ATTRIBUTES ##
  accepts_nested_attributes_for :hosts, allow_destroy: true
  validates_associated :hosts

  ## VALIDATIONS ##
  validates :name, :carrier_id, :rate_sheet_id, :routing_strategy,
            :profit_margin_type, :profit_margin, :max_duration, :max_cost, presence: true
  validates :name, uniqueness: {allow_blank: true}, length: {in: 3..25}
  validates :depth, presence: true, inclusion: { in: 0..10, allow_blank: true },
            numericality: {only_integer: true, allow_nil: true}, if: Proc.new {|t| t.routing_strategy == '1'}
  validates :call_limit, inclusion: { in: 0..10000, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  validates :cps_limit, inclusion: { in: 0..500, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  validates :max_cost, inclusion: { in: 0..1, allow_blank: true }

  validates :profit_margin_type, inclusion: { in: 0..1, allow_blank: true }
  validates :profit_margin, inclusion: {in: -1..1, allow_blank: true}, if: Proc.new {|t| t.profit_margin_type == '1' }
  validates :profit_margin, inclusion: {in: -500..500, allow_blank: true}, 
              numericality: {only_integer: true, allow_nil: true}, 
              if: Proc.new {|t| t.profit_margin_type == '0' }

  validates :try_timeout, inclusion: { in: 1..60, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  validates :pdd_timeout, inclusion: { in: 1..60, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  validates :ring_timeout, inclusion: { in: 1..120, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  validates :decimal_points, inclusion: { in: 2..8, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  validates :max_duration, inclusion: { in: 60..7200, allow_blank: true }, numericality: {only_integer: true, allow_nil: true}
  
  validates :force_cid, format: { with: /\A[\d\+]+\z/, allow_blank: true }
  validates :tech_prefix, format: { with: /\A[\d\#]+\z/, allow_blank: true }

  validates :lrn_source, inclusion: { in: IngressTrunk::LRN_SOURCES.keys, allow_blank: true }
  validates :routing_strategy, inclusion: { in: ROUTING_STRATEGIES.keys, allow_blank: false }

  def self.select_options(carrier_id = nil, include_all = true)
    if carrier_id.present?
      obj = self.where(carrier_id: carrier_id)
    else
      obj = self
    end
    
    unless include_all
      obj = obj.active
    end
    
    obj.all.collect {|t| [t.name, t.id]}
  end

  def self.rate_sheets_select_options(carrier_id = nil, egress_trunk_id = nil, include_all = true)
    obj = self.select('DISTINCT(rate_sheets.id), rate_sheets.name').joins(:rate_sheet)

    unless include_all
      obj = obj.active
    end

    if carrier_id.present?
      obj = obj.where(carrier_id: carrier_id)
    end

    if egress_trunk_id.present?
      obj = obj.where(id: egress_trunk_id)
    end

    obj.all.collect {|r| [r.name, r.id]}
  end

  def self.tech_prefixes_select_options(carrier_id = nil, egress_trunk_id = nil, include_all = true)
    obj = self.select("DISTINCT(tech_prefix)").where('tech_prefix IS NOT NULL AND tech_prefix != ""')

    unless include_all
      obj = obj.active
    end

    if carrier_id.present?
      obj = obj.where(carrier_id: carrier_id)
    end

    if egress_trunk_id.present?
      obj = obj.where(id: egress_trunk_id)
    end

    obj.all.collect {|t| [t.tech_prefix]}
  end
end
