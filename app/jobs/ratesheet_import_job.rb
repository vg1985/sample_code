class RatesheetImportJob < ActiveJob::Base
  queue_as :default

  def perform(rate_sheet_id, csv_file, options, user_action_id)
    Rails.logger.info 'options...' + options.inspect
    rate_sheet = RateSheet.find(rate_sheet_id)

    if options['delete_all']
      puts 'Delete all rows'
      ActiveRecord::Base.connection.execute("DELETE FROM rates WHERE rate_sheet_id = #{rate_sheet.id}")
    end

    if options['with_update']
      rate_sheet.import_with_update(csv_file, user_action_id, options['rounding'])
    else
      rate_sheet.import(csv_file, user_action_id, options['rounding'])  
    end
  end
end
