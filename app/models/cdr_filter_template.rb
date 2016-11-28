class CdrFilterTemplate < ActiveRecord::Base
	serialize :query

	## CONSTANTS ##
	DEFAULT_NAME = 'Default'

	## ASSOCIATIONS ##
	belongs_to :user

	## VALIDATIONS ##
  validates :name, presence: true, length: {minimum: 2, maximum: 25}
end
