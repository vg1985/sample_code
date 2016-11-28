class SmsLog
	#SmsLogAr.all.each{ |log| SmsLog.create(log.attributes.except("id", "message_id", "additional_info")) }
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: 'smsLogs'

  DT_ADMIN_COLS = [:carrier_name, :_id, :created_at, :direction, :status, :from_did_no, :recipients, :message]

  field :carrier_id, type: Integer
  field :carrier_name, type: String
  field :user_id, type: Integer
  field :did_id, type: Integer
  field :from_did_no, type: String
  field :from, type: String
  field :recipients, type: Array
  field :message, type: String
  field :direction, type: String
  field :status, type: String
  field :description, type: String
  field :unit_price, type: Float
  field :total_price, type: Float
  field :additional_info, type: Array
end