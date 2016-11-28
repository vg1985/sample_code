class Reseller < ActiveRecord::Base
  
  ## VALIDATIONS ##
  validates :name, presence: true
  
  ## ASSOCIATIONS ##
  has_many :carriers
  
  
end
