namespace :onetime do
	desc 'Export SMSLogs to MongoDB.'
	task export_smslogs_to_mongo: :environment do
		puts 'Exporting.....'
		SmsLogAr.all.each do |log|
			log_attrs = log.attributes.except('id', 'message_id')

			log_attrs["additional_info"] = [log_attrs["additional_info"]] unless log_attrs["additional_info"].is_a?(Array)
			log_attrs["carrier_name"] = log.carrier.company_name
			log_attrs["from_did_no"] = log.from_did.did if log.from_did.present?
			
			SmsLog.create(log_attrs)
		end
		puts 'Done'
	end
end

#1 , Monday