namespace :background do
	desc 'Store today\'s Carrier balances.'
	task set_carrier_balances: :environment do
		puts 'Set Carrier Balances.....'
		puts 'Started At.....' + Time.now.to_s
		Carrier.all.each do |c|
			balances = c.carrier_balances.last

			if balances.blank? || balances.beginning_ingress_credit != c.ingress_credit
				c.carrier_balances.create(day: Date.today + 1, beginning_ingress_credit: c.ingress_credit)
			end
		end
		puts 'Done'
		puts 'Finished At.....' + Time.now.to_s
	end

	desc 'Generate Invoices for carriers'
	task generate_invoices: :environment do
		puts 'Generating Invoices.....'
		puts 'Started At.....' + Time.now.to_s

		if Date.today.wday == 0
			carriers = Carrier.active
			if Setting.default_billing_cycle == Carrier::BILLING_CYCLE_WEEKLY
				carriers = carriers.where(["carriers.invoice_period IS NULL OR
					carriers.invoice_period = '' OR
					carriers.invoice_period = ?", Carrier::BILLING_CYCLE_WEEKLY])
			else
				carriers = carriers.where(['carriers.invoice_period = ?', Carrier::BILLING_CYCLE_WEEKLY])
			end

			#billing_start_date = Date.today.to_time - 6.days
			#billing_end_date = Date.yesterday.to_time.end_of_day

			billing_start_date = Time.parse('2016-02-01 00:00:00')
			billing_end_date = Time.parse('2016-02-07 23:59:59')
			
			data = {'key': APP_CONFIG['api_key']}
			data['date_group'] = 'date'

			carriers.all.each do |carrier|
				#data['egress_carrier_id'] = carrier.id
				data['egress_carrier_id'] = 1
				post_url = "#{APP_CONFIG['api_url']}/reports/summary/#{APP_CONFIG['api_customer']}/term/#{billing_start_date.iso8601}/#{billing_end_date.iso8601}"
				puts 'URL: ' + post_url.inspect
				puts 'Data...' + data.inspect
				result = RestClient.post post_url, data.to_json, content_type: :json
				result = JSON.parse(result)
				puts'response.......' + result.inspect

				
			end
		end

		if Date.today.day == 1
			carriers = Carrier.active
			if Setting.default_billing_cycle == Carrier::BILLING_CYCLE_MONTHLY
				carriers = carriers.where(["carriers.invoice_period IS NULL OR
					carriers.invoice_period = '' OR 
					carriers.invoice_period = ?", Carrier::BILLING_CYCLE_MONTHLY])
			else
				carriers = carrier.where(["carriers.invoice_period = ?", Carrier::BILLING_CYCLE_MONTHLY])
			end

			carriers.all.each do |carrier|

			end
		end
		
		puts 'Done'
		puts 'Finished At.....' + Time.now.to_s
	end
end

#1 , Monday