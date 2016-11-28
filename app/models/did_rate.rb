class DidRate < ActiveRecord::Base
  belongs_to :carrier

  validates :activation, :monthly, :per_minute, :bill_start, :bill_increment, presence: true, on: :create, allow_nil: true
  validates :bill_start, :bill_increment, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 60 }, allow_nil: true
  validates :activation, :monthly, :per_minute, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99.9999 }, allow_nil: true
  
  def self.defaults
    @defaults = @defaults || self.where(carrier_id: nil).first 
  end
  
  def to_arr
    [self.activation, self.monthly, self.per_minute, self.bill_start, self.bill_increment]
  end
end
