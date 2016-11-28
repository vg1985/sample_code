module UserActionsHelper
	def info_data(info)
		return '' if info.blank?
		
		(info.collect do |k, v|
			"#{k.to_s.humanize}: #{v.to_s.humanize}"
		end).join('<br />')
	end
end
