class SmsLogPreagg
  include Mongoid::Document
  include Mongoid::Timestamps

  field :total_sms, type: Integer
  field :total_price, type: Float
  field :outgoing, type: Integer
  field :outgoing_cost, type: Float
  field :incoming, type: Integer
  field :incoming_cost, type: Float
  field :forwarded, type: Integer
  field :forwarded_cost, type: Float
  field :successful, type: Integer
  field :failed, type: Integer
end