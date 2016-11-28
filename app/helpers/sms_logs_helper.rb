module SmsLogsHelper
	def recipients_status(recipients, additional_info)
		success = Array.new
		failed = Array.new

		recipients.each_with_index do |r, i|
			if additional_info[i].keys.include?(:error)
				success << r
			else
				failed << r
			end
		end

		[success, failed]
	end
end
