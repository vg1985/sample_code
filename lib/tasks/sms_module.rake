namespace :background do
	desc 'Pre-aggregate SMS Logs on per carrier per day.'
	task preagg_smslogs: :environment do
		puts 'Pre aggregating.....'
		puts 'Started At.....' + Time.now.to_s
		last_job = JobDate.where(key: 'smslog_preagg').first

		if last_job.blank?
			from_date = Date.yesterday.to_s(:db)
		else
			from_date = last_job.date.to_date.to_s(:db)
		end

		preagg_docs = SmsLog.collection.aggregate([
			{
      	'$match': { created_at: { '$gt': Time.parse("#{from_date} 23:59:59") } }
    	},
	    { 
	    	'$project': { carrier_id: 1, direction: 1, status: 1, total_price: 1, created_date: {'$dateToString': {format: '%Y-%m-%d', date: '$created_at'}} }
	    },
	    {
        '$group': {
          _id: {date: '$created_date', carrier_id: '$carrier_id'},
          total_sms: {'$sum': 1},
          total_price: {'$sum': '$total_price'},
          outgoing: {'$sum': {'$cond': [{'$eq': ['$direction', 'outgoing']}, 1, 0]}},
          outgoing_cost: {'$sum': {'$cond': [{'$eq': ['$direction', 'outgoing']}, '$total_price', 0]}},
          incoming: {'$sum': {'$cond': [{'$eq': ['$direction', 'incoming']}, 1, 0]}},
          incoming_cost: {'$sum': {'$cond': [{'$eq': ['$direction', 'incoming']}, '$total_price', 0]}},
          forwarded: {'$sum': {'$cond': [{'$eq': ['$direction', 'forward']}, 1, 0]}},
          forwarded_cost: {'$sum': {'$cond': [{'$eq': ['$direction', 'forward']}, '$total_price', 0]}},
          successful: {'$sum': {'$cond': [{'$eq': ['$status', 'success']}, 1, 0]}},
          failed: {'$sum': {'$cond': [{'$eq': ['$status', 'failed']}, 1, 0]}}
        }
	    }
		])

		preagg_docs.each do |doc|
			SmsLogPreagg.create(doc)
		end

		job_date = JobDate.where(key: 'smslog_preagg')
		if job_date.exists?
			job_date.first.update_attribute(:date, Time.now)
		else
			JobDate.create(key: 'smslog_preagg', date: Time.now)
		end
	
		puts 'Done'
		puts 'Finished At.....' + Time.now.to_s
	end
end