class Rate < ActiveRecord::Base

  EDIT_SET_TO = 1
  EDIT_ADD = 2
  EDIT_SUBTRACT = 3
  EDIT_MULTIPLY = 4

  EDIT_OPERATIONS = { EDIT_SET_TO => 'Set To', EDIT_ADD => 'Add', EDIT_SUBTRACT => 'Subtract', EDIT_MULTIPLY => 'Multiply' }

  #attr_accessor :skip_uniq_code_validation

  ## VALIDATIONS ##
  validates :code_country, length: { maximum: 10, allow_blank: true }
  validates :code_name, length: { maximum: 25, allow_blank: true }
  validates :code, presence: true, numericality: { only_integer: true },
            length: { maximum: 25, allow_blank: true }
  #validates :code, uniqueness: { allow_blank: true, scope: [:rate_sheet_id, :effective_time] }, 
            #unless: :skip_uniq_code_validation
            
  validates :rate, presence: true
  validates :inter_rate, :intra_rate, presence: true, 
            numericality: { allow_blank: true, less_than_or_equal_to: 99.999999 },
            if: Proc.new {|rate| rate.rate_sheet.rate_sheet_type == RateSheet::US_JURISDICTION }

  validates :rate,
    numericality: { allow_blank: true, less_than_or_equal_to: 99.999999 }
  
  validates :bill_start, presence: true, numericality: { only_integer: true, allow_blank: true, greater_than: 0, less_than_or_equal_to: 60 } 
  validates :bill_increment, presence: true, numericality: { only_integer: true, allow_blank: true, greater_than: 0, less_than_or_equal_to: 60 } 
  validates :setup_fee, presence: true, numericality: { allow_blank: true, less_than_or_equal_to: 99.9999 }

  validate :valid_effective_time
  validate :rates_precision

  ## ASSOCIATIONS ##
  belongs_to :rate_sheet

  def effective_time
    if self[:effective_time].present?
      self[:effective_time].to_s(:effective_time)
    else 
      self[:effective_time]
    end
  end

  def self.round_off_sql(column, round_to)
    "ceil((#{column})* #{10**round_to})/#{10**round_to}"
  end

  private
  def valid_effective_time
    if self[:effective_time].blank? || self[:effective_time].class != ActiveSupport::TimeWithZone
      errors.add(:effective_time, 'must be a valid datetime')
    end
  end

  def rates_precision
    if rate.present? && (rate < 0 || rate > 0 && rate < 0.000001)
      errors.add(:rate, 'Invalid value')
    end

    if setup_fee.present? && (setup_fee < 0 || setup_fee > 0 && setup_fee < 0.0001)
      errors.add(:setup_fee, 'Invalid value')
    end

    if rate_sheet.rate_sheet_type == RateSheet::US_JURISDICTION &&
      intra_rate.present? && (intra_rate < 0 || intra_rate > 0 && intra_rate < 0.000001)

      errors.add(:intra_rate, 'Invalid value')
    end

    if rate_sheet.rate_sheet_type == RateSheet::US_JURISDICTION &&
      inter_rate.present? && (inter_rate < 0 || inter_rate > 0 && inter_rate < 0.000001)

      errors.add(:inter_rate, 'Invalid value')
    end
  end

end
