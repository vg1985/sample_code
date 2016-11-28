module RateSheetWrapper

  def to_csv
    CSV.generate do |csv|
      csv << column_names
      self.rates.each do |rate|
        csv << rate.attributes.values_at(*column_names)
      end
    end
  end

  def ratesheet_import(csv_file, user_action)
    success_rows = 0
    failed_rows = 0

    begin
      csv = SmarterCSV.process(File.open(csv_file))

      begin
        csv.each_with_index do |row, index|
          rate = self.rates.find_or_initialize_by(code: row[:code], effective_time: row[:effective_time])
          rate.attributes = row
          rate.save!
          success_rows += 1
        end
      
      rescue => e
        Rails.logger.info "ERROR : #{e.message}"
        user_action.add_details('failed_csv_row', {error: e.message})
        failed_rows += 1
      end
    
    rescue => e
      user_action.update_attributes(status: 'failed', info: {error: e.message})
    end
    
    if failed_rows.present?
      action_attrs = {status: 'successful'}
    else
      action_attrs = {status: 'partially_successful'}
    end
    action_attrs[:info] = {failed_rows: failed_rows, success_rows: success_rows}

    user_actions.update_attributes(action_attrs)
  end

  def create_rate_sheet_notification
    self.rate_sheet_notifications.create!
  end

  ## PRIVATE METHODS ##
  private

  def create_log_entries(rates, notification_id, ratesheets_folder)
    system "mkdir", "-p", "log/#{ratesheets_folder}"
    File.open("log/#{ratesheets_folder}/ratesheet#{id}#{notification_id}.log", 'wb') do |f|
      rates.each do |rate, index|
        f.write "Line #{index + 1} : "
        f.write rate.errors.messages.collect {|m| "#{m[0].to_s} #{m[1].to_sentence}"}.to_sentence
        f.write "\n"
      end
    end
  end

end
