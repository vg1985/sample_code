class AdminsCarrier < ActiveRecord::Base
  
  ## VALIDATIONS ##
  validates :carrier_id, presence: true
  
  ## ASSICIATIONS ##
  belongs_to :admin, class_name: "User"
  belongs_to :carrier
  
end
