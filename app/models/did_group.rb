class DidGroup < ActiveRecord::Base
	UNGROUPED_NAME = 'Ungrouped'
	
	belongs_to :carrier
	has_many :dids

	validates :name, presence: true, length: {in: 3..254}, uniqueness: {scope: :carrier_id}, format: {with: /\A[a-z0-9\-\s]+\z/i}
	validates :description, length: {minimum: 3}, allow_blank: true
end
