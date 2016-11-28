class SmsLogsController < ApplicationController
	after_action :verify_authorized

	def index
		authorize :sms_log, :index?

		if policy(:order).select_carrier? 
		  @carriers = Carrier.all
		end
	end

	def show
		authorize :sms_log, :show?

		@sms_log = SmsLog.find(params[:id])

		respond_to do |format|
			format.html { render layout: false }
		end
	end

	def dt_message_logs_interplay
	  authorize :sms_log, :index?
	  
	  filter_query = {}

	  if policy(:sms_log).select_carrier?
	    filter_query[:carrier_id] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?
	    filter_query[:status] = params[:columns]['4']['search']['value'] if params[:columns]['4']['search']['value'].present?
	    filter_query[:direction] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?
	  else
	    filter_query[:status] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?
	    filter_query[:direction] = params[:columns]['2']['search']['value'] if params[:columns]['2']['search']['value'].present?
	  end

	  select_clause = [:from, :from_did_no, :status, :direction,
						:message, :recipients, :created_at];

	  order_by = {}
    order_by[SmsLog::DT_ADMIN_COLS[params[:order]['0'][:column].to_i]] = params[:order]['0'][:dir]
      
	  if policy(:sms_log).select_carrier?
	    select_clause += [:carrier_id, :carrier_name]
	    @messages = SmsLog.only(select_clause).order_by(order_by).where(filter_query)

	    if params['search']['value'].present?
	    	search = Regexp.new(params['search']['value'])
	    	@messages = @messages.or([{_id: params['search']['value']}, {from_id_no: search}, {recipients: search}, {message: search}])
	    end

	    if params[:columns]['2']['search']['value'].present?
	    	date_range = params[:columns]['2']['search']['value'].split('|')
	    	date_range[0] = Time.zone.parse(date_range[0]).iso8601
	    	date_range[1] = Time.zone.parse(date_range[1]).iso8601
	    	@messages = @messages.where(created_at: {
																        '$gte': "ISODate(#{date_range[0]})",
																        '$lt': "ISODate(#{date_range[1]})"
																   	})
	    end
	    @messages = @messages.offset((params[:page].to_i - 1) * params[:length].to_i).limit(params[:length].to_i)
	      
	    @data = @messages.collect do |message|
	    	actions = [message.id.to_s]
	      #{
	      #  'DT_RowClass': 'clickable-row', 'DT_RowData': {'href': "#{sms_log_url(message)}"},
	      #  '0': message.company_name, '1': message.message_id, '2': message.created_at.to_s(:db),
	      #  '3': message.status, '4': message.from_did_no, '5': message.recipients, '6': message.message
	      #}
	      if message.direction == 'forward'
          sender =  message.from
          recipient = message.from_did_no
          forward_to = message.recipients.join(', ')
        else
          sender = message.from_did_no.present? ? message.from_did_no : message.from
          recipient = message.recipients.join(', ')
          forward_to = '-'
        end
        
        [ message.carrier_name, message.id.to_s, message.created_at.in_time_zone(current_user.timezone).to_s(:carrier), 
          message.direction.titleize, message.status, sender,
          recipient, forward_to,
          message.message, actions
        ]

	    end

	  else
	    @messages = SmsLog.only(select_clause).order_by(order_by).where(filter_query)
	    if params['search']['value'].present?
	      search = Regexp.new(params['search']['value'])
        @messages = @messages.or([{from_id_no: search}, {recipients: search}, {message: search}])
	    end

	    if params[:columns]['1']['search']['value'].present?
	    	date_range = params[:columns]['1']['search']['value'].split('|')
	    	date_range[0] = Time.zone.parse(date_range[0]).iso8601
	    	date_range[1] = Time.zone.parse(date_range[1]).iso8601
	    	@messages = @messages.where(created_at: {
																        '$gte': "ISODate(#{date_range[0]})",
																        '$lt': "ISODate(#{date_range[1]})"
																    })
	    end
	    @messages = @messages.offset((params[:page].to_i - 1) * params[:length].to_i).limit(params[:length].to_i)
      @data = @messages.collect do |message|
	    	actions = [message.id.to_s]
	      #{
	      #  'DT_RowClass': 'clickable-row', 'DT_RowData': {'href': "#{sms_log_url(message)}"},
	      #  '0': message.message_id, '1': message.created_at.to_s(:db),
	      #  '2': message.status, '3': message.from_did_no, '4': message.user_name, '5': message.description
	      #}
	      if message.direction == 'forward'
	        sender =  message.from
          recipient = message.from_did_no
          forward_to = message.recipients.join(', ')
	      else
	        sender = message.from_did_no.present? ? message.from_did_no : message.from
          recipient = message.recipients.join(', ')
          forward_to = '-'
	      end
	      
        [ message.id.to_s, message.created_at.in_time_zone(carrier.timezone).to_s(:carrier), 
          message.direction.titleize, message.status, sender,
          recipient, forward_to,
          message.message, actions
        ]
	    
	    end
	  end

	  respond_to do |format|
	    format.json
	  end
	end
end
