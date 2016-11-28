module SupportHelper
	def status_label(status)
		case status
		when 'pending'
			'<span class="label label-danger" title="Pending">Pending</span>'
		when 'open'
			'<span class="label label-warning" title="Open">Open</span>'
		when 'new'
			'<span class="label label-info" title="New">New</span>'
		else
			"<span>#{status.titlecase}</span>"
		end
	end

	def priority_label(priority)
		case priority
		when 'urgent'
			'<span class="label label-danger" title="Critical">Critical</span>'
		when 'high'
			'<span class="label label-warning" title="High">High</span>'
		when 'normal'
			'<span class="label label-info" title="Normal">Normal</span>'
		when 'low'
			'<span class="label label-success" title="Normal">Normal</span>'
		else
			'<span>--</span>'
		end
	end

	def status_options
		{
			'All Statuses': '-1',
			'New': 'new',
			'Open': 'open',
			'Pending': 'pending',
			'Solved': 'solved',
			'Closed': 'closed'
		}
	end

	def priority_options
		{
			'Critical': 'urgent',
			'High': 'high',
			'Normal': 'normal',
			'Low': 'low'
		}
	end
end
