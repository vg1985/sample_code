class RateSheetNotification < ActiveRecord::Base

  ## CONSTANTS ##
  enum status: ["in_progress", "successful", "partial_successful", "failed"]

  ## VALIDATIONS ##
  validates :rate_sheet_id, presence: true

  ## ASSOCIATIONS ##
  belongs_to :rate_sheet, polymorphic: true

end
