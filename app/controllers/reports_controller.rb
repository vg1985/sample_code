class ReportsController < ApplicationController
	include ReportsHelper

	after_action :verify_authorized

	def profit
		authorize :report, :profit?

		include_all = params[:include_all] == '1' ? true : false

		@carriers = Carrier.for_select(include_all)
		@ingress_trunks = IngressTrunk.select_options(nil, include_all)
		@egress_trunks = EgressTrunk.select_options(nil, include_all)
		@rate_sheets = RateSheet.for_select
		@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(nil, nil, include_all)
		@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(nil, nil, include_all)
		@routings = Routing.for_select
	end

	def get_profit
		authorize :report,  :get_profit?

		if params[:to_date].present? && params[:from_date].present?
			
			@data = {'key': APP_CONFIG['api_key']}

			begin
				init_profit_post_data
				logger.info 'data...' + @data.inspect
				
				if 'term' == params[:report_Type]
					post_url = "#{APP_CONFIG['api_url']}/reports/profit/#{APP_CONFIG['api_customer']}/term/#{@from_date}/#{@to_date}"
				else
					post_url = "#{APP_CONFIG['api_url']}/reports/profit/#{APP_CONFIG['api_customer']}/orig/#{@from_date}/#{@to_date}"
				end

				resource = rest_resource(post_url)
				
				begin
					@timeout = false                                		
					result = resource.post(@data.to_json, content_type: :json)
				
				rescue RestClient::RequestTimeout
					@timeout = true

					respond_to do |format|
						format.js {
							render 'get_profit' and return
						}

						format.csv {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}

						format.pdf {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}

						format.xls {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}
					end
				end

				@result = JSON.parse(result)
				logger.info 'response.......' + @result.inspect

				#{"total_duration":345609.44999999995,"total_billtime":2880078.75,"total_ingress_cost":31680.870000000003,"total_egress_cost":28570.379999999997,"total_calls":345607,"total_nonzero":345428,"avg_profit_percent":1555.2399999999998,"total_profit":3110.4799999999996,"start":"2015-01-06T00:00:00+05:30","end":"2015-01-09T23:59:59+05:30","query_time":"00:07.184","group":[{"id":{"ingress_carrier_id":1,"calendar":"2015","ingress_carrier_name":null},"duration":173013.688,"billtime":1441780.7333333334,"ingress_cost":15859.59,"egress_cost":14302.46,"calls":172952,"nonzero":172856,"profit":1557.12,"profit_percent":9.82},{"id":{"ingress_carrier_id":2,"calendar":"2015","ingress_carrier_name":null},"duration":172595.762,"billtime":1438298.0166666666,"ingress_cost":15821.28,"egress_cost":14267.92,"calls":172655,"nonzero":172572,"profit":1553.36,"profit_percent":9.82}]}	
			rescue RestClient::RequestTimeout => timeout
				@result = {error: true, message: 'Timeout:Could not reach API server.'}
			end
		else
			logger.info 'Invalid parameters...'
		end

		respond_to do |format|
			format.js
			
			format.csv {
				send_data profit_generate_csv, type: 'text/csv', filename: downloaded_filename('Profit Report', 'csv'), disposition: 'attachment'
			}

			format.xls {
				filename = profit_write_xls
				send_file filename, type: 'application/vnd.ms-excel', filename: downloaded_filename('Profit Report', 'xls'), stream: false
			}

			format.pdf {
				if 'term' == params[:report_Type]
					@report_name = 'Profit Termination Report'
				else
					@report_name = 'Profit Origination Report'
				end

	      render pdf: downloaded_filename('Profit Report'),
	             template: 'reports/export_profit.pdf.erb',
	             disposition: 'attachment',
	             layout: 'reports_pdf.html'
      }
		end
	end

	def summary
		authorize :report, :summary?

		include_all = params[:include_all] == '1' ? true : false

		if policy(:report).select_carrier?
			@carriers = Carrier.for_select(include_all)
			@ingress_trunks = IngressTrunk.select_options(nil, include_all)
			@egress_trunks = EgressTrunk.select_options(nil, include_all)
			@rate_sheets = RateSheet.for_select
			@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(nil, nil, include_all)
			@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(nil, nil, include_all)
			@routings = Routing.for_select
		else
			@ingress_trunks = IngressTrunk.select_options(current_user.carrier.id, false)
			@rate_sheets = IngressTrunk.
											rate_sheets_select_options(current_user.carrier.id, nil, false)
			@ingress_tech_prefixes = IngressTrunk.
															tech_prefixes_select_options(current_user.carrier.id, nil, false)
		end
	end

	def get_summary
		authorize :report, :get_summary?

		if params[:to_date].present? && params[:from_date].present?
			
			@data = {'key': APP_CONFIG['api_key']}

			#begin
				init_profit_post_data

				if 'term' == params[:report_Type]
					post_url = "#{APP_CONFIG['api_url']}/reports/summary/#{APP_CONFIG['api_customer']}/term/#{@from_date}/#{@to_date}"
				else
					post_url = "#{APP_CONFIG['api_url']}/reports/summary/#{APP_CONFIG['api_customer']}/orig/#{@from_date}/#{@to_date}"
				end

				resource = rest_resource(post_url)

				begin
					@timeout = false                                		
					result = resource.post(@data.to_json, content_type: :json)

				rescue RestClient::RequestTimeout
					@timeout = true

					respond_to do |format|
						format.js {
							render 'get_summary' and return
						}

						format.csv {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}

						format.pdf {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}

						format.xls {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}
					end
				end

				@result = JSON.parse(result)
				logger.info 'response.......' + @result.inspect

=begin				
				{"avg_asr"=>1, "avg_acd"=>8.33, "avg_pdd"=>1000, 
				"total_duration"=>345501.0240000001, "total_billtime"=>2879175.1999999997, "total_cost"=>31670.93, 
				"avg_rate"=>0.01, "total_calls"=>345622, "total_nonzero"=>345445, "total_lrn_calls"=>0, "
				total_inter"=>0, "total_intra"=>0, 
				"start"=>"2015-01-06T00:00:00Z", "end"=>"2015-01-09T23:59:59Z", 
				"query_time"=>"00:10.269", 
				"group"=>[
					{
						"id" => {"ingress_trunk_id"=>9, "calendar"=>"2015-01-09", "ingress_trunk_name"=>"Nationwide Auto Guard"}, 
						"asr"=>1, "acd"=>8.35, "pdd"=>1000, "duration"=>6036.616, 
						"billtime"=>50305.13333333333, "cost"=>553.36, "calls"=>6029, 
						"avg_rate"=>0, "nonzero"=>6028, "lrn_calls"=>0, "intra_rate"=>0}, 
					{
						"id" => {"ingress_trunk_id"=>4, "calendar"=>"2015-01-09", "ingress_trunk_name"=>"CHA"}, 
						"asr"=>1, "acd"=>8.36, "pdd"=>1000, "duration"=>6248.738, 
						"billtime"=>52072.816666666666, "cost"=>572.8, "calls"=>6229, 
						"avg_rate"=>0, "nonzero"=>6228, "lrn_calls"=>0, "intra_rate"=>0
					}
				]
=end				
			#rescue

			#end
		else
			logger.info 'Invalid parameters...'
		end

		respond_to do |format|
			format.js
			
			format.csv {
				send_data summary_generate_csv, type: 'text/csv', filename: downloaded_filename('Summary Report', 'csv'), disposition: 'attachment'
			}

			format.xls {
				filename = summary_write_xls
				send_file filename, type: 'application/vnd.ms-excel', filename: downloaded_filename('Summary Report', 'xls'), stream: false
			}

			format.pdf { 
				if 'term' == params[:report_Type]
					@report_name = 'Summary Termination Report'
				else
					@report_name = 'Summary Origination Report'
				end

	      render pdf: downloaded_filename('Summary Report'),
	             template: 'reports/export_summary.pdf.erb',
	             disposition: 'attachment',
	             layout: 'reports_pdf.html'
      }
		end
	end

	def cdr_search
		authorize :report, :cdr_search?

		#create default CDR search template
		if current_user.default_cdr_filter_template.blank?
			current_user.cdr_filter_templates.create(is_default: true, name: CdrFilterTemplate::DEFAULT_NAME)
		end

		@query = {}

		if params[:filter].present?
			@user_filter = current_user.cdr_filter_templates.where(id: params[:filter]).first
			@query = @user_filter.query || {}
		end

		if params[:filter].blank? || @user_filter.blank?
			@cdr_templates = current_user.cdr_filter_templates.order('is_default DESC, name ASC')
			
			if policy(:report).select_carrier?
				@include_all = params[:include_all] == '1' ? true : false
				@carriers = Carrier.for_select(@include_all)
				@egress_trunks = EgressTrunk.select_options(nil, @include_all)
				@rate_sheets = RateSheet.for_select
				@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(nil, nil, @include_all)
				@ingress_trunks = IngressTrunk.select_options(nil, @include_all)
				@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(nil, nil, @include_all)
			else
				carrier_id = current_user.carrier.id
				@ingress_trunks = IngressTrunk.select_options(carrier_id, @include_all)
				@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(carrier_id, nil, @include_all)
			end
		else
			if policy(:report).select_carrier?
				@include_all = @query['include_all_chk'] == '1' ? true : false
				@carriers = Carrier.for_select(@include_all)
				@ingress_trunks = IngressTrunk.select_options(@query['ingress_carrier_id'], @include_all)
				@egress_trunks = EgressTrunk.select_options(@query['egress_carrier_id'], @include_all)
				@rate_sheets = IngressTrunk.rate_sheets_select_options(@query['ingress_carrier_id'], @query['ingress_trunk_id'], @include_all)
				@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(@query['ingress_carrier_id'], @query['ingress_trunk_id'], @include_all)
				@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(@query['egress_carrier_id'], @query['egress_trunk_id'], @include_all)
			else
				carrier = current_user.carrier.id
				@ingress_trunks = IngressTrunk.select_options(carrier_id, @include_all)
				@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(carrier_id, @query['ingress_trunk_id'], @include_all)
			end
		end

		respond_to do |format|
			format.html
			format.js
		end
	end

	def get_cdr_search
		authorize :report, :cdr_search?

		if params[:to_date].present? && params[:from_date].present?
			
			@data = {'key': APP_CONFIG['api_key']}

			#begin
				init_cdrsearch_post_data
				
				logger.info(@data)
				session['cdr_search_filter'] = {'from_date': @from_date, 'to_date': @to_date, 'data': @data}
				
				post_url = "#{APP_CONFIG['api_url']}/cdr/search/#{APP_CONFIG['api_customer']}/#{@from_date}/#{@to_date}"

				result = RestClient.post post_url, @data.to_json, content_type: :json

				@result = JSON.parse(result)

				if @result['cdrs'].present?
					session['cdr_search_cols'] = @data['columns'].split(',')
				end
				
				logger.info 'response.......' + @result.inspect
			#rescue

			#end
		else
			logger.info 'Invalid parameters...'
		end

		respond_to do |format|
			format.js {
				if params[:page_action] == 'export'
					render js: "window.location.href='#{reports_cdr_logs_path}?refresh=1'"
				end
			}
			
			format.csv {
				send_data cdr_search_generate_csv, type: 'text/csv', filename: downloaded_filename('CDR Search Report', 'csv'), disposition: 'attachment'
			}

			format.xls {
				filename = cdr_search_write_xls
				send_file filename, type: 'application/vnd.ms-excel', filename: downloaded_filename('CDR Search Report', 'xls'), stream: false
			}
		end
	end

	def paginated_cdr_search
		authorize :report, :cdr_search?

		if session['cdr_search_filter'][:data].blank?
			respond_to do |format|
				format.json { render text: 'Invalid request' and return}
			end
		end

		@data = session['cdr_search_filter'][:data].dup
		if params[:order].present?
			@data['sort_by'] = session['cdr_search_cols'][params[:order]['0'][:column].to_i]
			@data['order'] = params[:order]['0'][:dir] == 'asc' ? 1 : -1
		end
		
		@data['rows'] = params[:length]
		@data['page'] = params[:page].to_i - 1
		logger.info(@data)
		post_url = "#{APP_CONFIG['api_url']}/cdr/search/#{session['cdr_search_filter'][:from_date]}/#{session['cdr_search_filter'][:to_date]}"
		result = RestClient.post post_url, @data.to_json, content_type: :json

		@result = JSON.parse(result)
		#logger.info 'response.......' + @result.inspect

		col_order = @data['columns'].split(',')
		@data = @result['cdrs'].collect do |rec|
			col_order.collect do |key|
				cdr_search_format_value(key, rec[key])
			end
    end

		respond_to do |format|
			format.json
		end
	end

	def did_search
    authorize :report, :did_search?

    #create default CDR search template
    if current_user.default_cdr_filter_template.blank?
      current_user.cdr_filter_templates.create(is_default: true, name: CdrFilterTemplate::DEFAULT_NAME)
    end

    @query = {}

    if params[:filter].present?
      @user_filter = current_user.cdr_filter_templates.where(id: params[:filter]).first
      @query = @user_filter.query || {}
    end

    if params[:filter].blank? || @user_filter.blank?
      @cdr_templates = current_user.cdr_filter_templates.order('is_default DESC, name ASC')
      
      if policy(:report).select_carrier?
        @include_all = params[:include_all] == '1' ? true : false
        @carriers = Carrier.for_select(@include_all)
        @egress_trunks = EgressTrunk.select_options(nil, @include_all)
        @rate_sheets = RateSheet.for_select
        @egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(nil, nil, @include_all)
        @ingress_trunks = IngressTrunk.select_options(nil, @include_all)
        @ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(nil, nil, @include_all)
      else
        carrier_id = current_user.carrier.id
        @ingress_trunks = IngressTrunk.select_options(carrier_id, @include_all)
        @ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(carrier_id, nil, @include_all)
      end
    else
      if policy(:report).select_carrier?
        @include_all = @query['include_all_chk'] == '1' ? true : false
        @carriers = Carrier.for_select(@include_all)
        @ingress_trunks = IngressTrunk.select_options(@query['ingress_carrier_id'], @include_all)
        @egress_trunks = EgressTrunk.select_options(@query['egress_carrier_id'], @include_all)
        @rate_sheets = IngressTrunk.rate_sheets_select_options(@query['ingress_carrier_id'], @query['ingress_trunk_id'], @include_all)
        @ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(@query['ingress_carrier_id'], @query['ingress_trunk_id'], @include_all)
        @egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(@query['egress_carrier_id'], @query['egress_trunk_id'], @include_all)
      else
        carrier = current_user.carrier.id
        @ingress_trunks = IngressTrunk.select_options(carrier_id, @include_all)
        @ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(carrier_id, @query['ingress_trunk_id'], @include_all)
      end
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def get_did_search
    authorize :report, :did_search?

    if params[:to_date].present? && params[:from_date].present?
      
      @data = {'key': APP_CONFIG['api_key']}

      #begin
        init_cdrsearch_post_data
        
        logger.info(@data)
        session['cdr_search_filter'] = {'from_date': @from_date, 'to_date': @to_date, 'data': @data}
        
        post_url = "#{APP_CONFIG['api_url']}/cdr/search/#{APP_CONFIG['api_customer']}/#{@from_date}/#{@to_date}"

        result = RestClient.post post_url, @data.to_json, content_type: :json

        @result = JSON.parse(result)

        if @result['cdrs'].present?
          session['cdr_search_cols'] = @data['columns'].split(',')
        end
        
        logger.info 'response.......' + @result.inspect
      #rescue

      #end
    else
      logger.info 'Invalid parameters...'
    end

    respond_to do |format|
      format.js {
        if params[:page_action] == 'export'
          render js: "window.location.href='#{reports_cdr_logs_path}?refresh=1'"
        end
      }
      
      format.csv {
        send_data cdr_search_generate_csv, type: 'text/csv', filename: downloaded_filename('CDR Search Report', 'csv'), disposition: 'attachment'
      }

      format.xls {
        filename = cdr_search_write_xls
        send_file filename, type: 'application/vnd.ms-excel', filename: downloaded_filename('CDR Search Report', 'xls'), stream: false
      }
    end
  end

  def paginated_did_search
    authorize :report, :did_search?

    if session['cdr_search_filter'][:data].blank?
      respond_to do |format|
        format.json { render text: 'Invalid request' and return}
      end
    end

    @data = session['cdr_search_filter'][:data].dup
    if params[:order].present?
      @data['sort_by'] = session['cdr_search_cols'][params[:order]['0'][:column].to_i]
      @data['order'] = params[:order]['0'][:dir] == 'asc' ? 1 : -1
    end
    
    @data['rows'] = params[:length]
    @data['page'] = params[:page].to_i - 1
    logger.info(@data)
    post_url = "#{APP_CONFIG['api_url']}/cdr/search/#{session['cdr_search_filter'][:from_date]}/#{session['cdr_search_filter'][:to_date]}"
    result = RestClient.post post_url, @data.to_json, content_type: :json

    @result = JSON.parse(result)
    #logger.info 'response.......' + @result.inspect

    col_order = @data['columns'].split(',')
    @data = @result['cdrs'].collect do |rec|
      col_order.collect do |key|
        cdr_search_format_value(key, rec[key])
      end
    end

    respond_to do |format|
      format.json
    end
  end

	def did
		authorize :report, :did?

		if policy(:report).select_carrier?
			include_all = params[:include_all] == '1' ? true : false
			@carriers = Carrier.for_select(include_all)
		end
	end

	def get_did
		authorize :report, :get_did?

		if params[:to_date].present? && params[:from_date].present?
			
			@data = {'key': APP_CONFIG['api_key']}

			#begin
				init_did_post_data
				
				post_url = "#{APP_CONFIG['api_url']}/reports/did/#{APP_CONFIG['api_customer']}/#{@from_date}/#{@to_date}"				

				resource = rest_resource(post_url)

				begin
					@timeout = false                                		
					result = resource.post(@data.to_json, content_type: :json)
				
				rescue RestClient::RequestTimeout
					@timeout = true

					respond_to do |format|
						format.js {
							render 'get_did' and return
						}

						format.csv {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}

						format.pdf {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}

						format.xls {
							flash[:error] = 'Error: Request Timeout'
							redirect_to :back and return
						}
					end
				end

				@result = JSON.parse(result)
				logger.info 'response.......' + @result.inspect
		else
			logger.info 'Invalid parameters...'
		end

		respond_to do |format|
			format.js {
				if params[:page_action] == 'export'
					render js: "window.location.href='#{reports_cdr_logs_path}?refresh=1'"
				end
			}
			
			format.csv {
				send_data did_generate_csv, type: 'text/csv', filename: downloaded_filename('CDR Search Report', 'csv'), disposition: 'attachment'
			}

			format.xls {
				filename = did_write_xls
				send_file filename, type: 'application/vnd.ms-excel', filename: downloaded_filename('DID Report', 'xls'), stream: false
			}

			format.pdf {
				@report_name = 'DID Report'

        render pdf: downloaded_filename('DID Report'),
	             template: 'reports/export_did.pdf.erb',
	             disposition: 'attachment',
	             layout: 'reports_pdf.html'
      }
		end
	end

	def sms
		authorize :report, :sms?

		if policy(:report).select_carrier?
			include_all = params[:include_all] == '1' ? true : false
			@carriers = Carrier.for_select(include_all)
		end
	end

	def get_sms
		authorize :report, :get_sms?

		@to_date = ActiveSupport::TimeZone[params[:time_zone]].parse(params[:to_date]) rescue nil
		@from_date = ActiveSupport::TimeZone[params[:time_zone]].parse(params[:from_date]) rescue nil

		if @to_date.present? && @from_date.present?
			
			select_clause = 'COUNT(sms_logs.id) AS total_sms,
				SUM(sms_logs.total_price) AS total_cost,
				COUNT(CASE WHEN direction = "outgoing" THEN 1 ELSE NULL END) AS outgoing,
				SUM(CASE WHEN direction = "outgoing" THEN total_price ELSE 0 END) AS outgoing_cost,
				COUNT(CASE WHEN direction = "incoming" THEN 1 ELSE NULL END) AS incoming,
				SUM(CASE WHEN direction = "incoming" THEN total_price ELSE 0 END) AS incoming_cost,
				COUNT(CASE WHEN direction = "forward" THEN 1 ELSE NULL END) AS forwarded,
				SUM(CASE WHEN direction = "forward" THEN total_price ELSE 0 END) AS forwarded_cost,
				COUNT(CASE WHEN status = "success" THEN 1 ELSE NULL END) AS successful,
				COUNT(CASE WHEN status = "failed" THEN 1 ELSE NULL END) AS failed, '
			
			case params[:group_by]
			when 'sms_carrier_id'
				select_clause += 'carriers.company_name'
				order_by = 'carriers.company_name, carriers.id'
				group_by = 'sms_logs.carrier_id'
			when 'date'
				select_clause += 'DATE(sms_logs.created_at) AS sdate'
				order_by = 'sdate, total_cost'
				group_by = 'sdate'
			when 'month'
				select_clause += 'CONCAT( MONTH( sms_logs.created_at ) , \'-\', YEAR( sms_logs.created_at ) ) AS sdate '
				order_by = 'sdate, total_cost'
				group_by = 'sdate'
			when 'year'
				select_clause += 'YEAR(sms_logs.created_at) AS sdate'
				order_by = 'sdate, total_cost'
				group_by = 'sdate'
			end

			@sms_logs = SmsLog.select(select_clause).
			where(['sms_logs.created_at BETWEEN ? AND ?', @from_date.utc, @to_date.utc]).
			group(group_by).order(order_by)

			if policy(:report).select_carrier?
				if 'sms_carrier_id' == params[:group_by]
					@sms_logs = @sms_logs.joins(:carrier)
				end
			else
				@sms_logs = @sms_logs.where(carrier_id: current_user.carrier.id)
			end
		end

		respond_to do |format|
			format.js {
				if params[:page_action] == 'export'
					render js: "window.location.href='#{reports_cdr_logs_path}?refresh=1'"
				end
			}
			
			format.csv {
				send_data sms_generate_csv, type: 'text/csv',
				filename: downloaded_filename('SMS Report', 'csv'),
				disposition: 'attachment'
			}

			format.xls {
				filename = sms_write_xls
				send_file filename, type: 'application/vnd.ms-excel',
				          filename: downloaded_filename('SMS Report', 'xls'),
				          stream: false
			}

			format.pdf { 
				@report_name = 'SMS Report'

        render pdf: downloaded_filename('SMS Report'),
	             template: 'reports/export_sms.pdf.erb',
	             disposition: 'attachment',
	             layout: 'reports_pdf.html'
      }
		end
	end

	def cdr_templates
		authorize :report, :cdr_templates?

		@templates = current_user.cdr_filter_templates.where('is_default = 0 OR is_default IS NULL').order('is_default DESC, name ASC')
	end
	
	def remove_cdr_template
		authorize :report, :remove_cdr_template?

		@template = current_user.cdr_filter_templates.where(['id = ? AND is_default = 0 OR is_default IS NULL', params[:id]]).first
		@template.destroy if @template.present?

		@templates = current_user.cdr_filter_templates.order('is_default DESC, name ASC')
		flash[:notice] = 'Template has been removed sucessfully.'
		respond_to do |format|
			format.html { redirect_to action: 'cdr_templates'  }
		end
	end

	def cdr_logs
		authorize :report, :cdr_logs?

		respond_to do |format|
			format.html
			format.js
		end
	end

	def get_cdr_logs
		authorize :report, :cdr_logs?

		if params[:to_date].present? && params[:from_date].present?
			
			@data = {'key': APP_CONFIG['api_key']}

			#begin
				init_cdrlogs_post_data
				logger.info 'data........' + @data.inspect
				session['cdr_logs_filter'] = {'data': @data}

				post_url = "#{APP_CONFIG['api_url']}/cdr/list/exported"

				result = RestClient.post post_url, @data.to_json, content_type: :json

				@result = JSON.parse(result)
				
				logger.info 'response.......' + @result.inspect
			#rescue

			#end
		else
			logger.info 'Invalid parameters...'
		end

		respond_to do |format|
			format.js
		end
	end

	def paginated_cdr_logs
		authorize :report, :cdr_logs?
		
		if session['cdr_logs_filter'][:data].blank?
			respond_to do |format|
				format.json { render text: 'Invalid request' and return}
			end
		end

		@data = session['cdr_logs_filter'][:data].dup
		@data['rows'] = params[:length]
		@data['page'] = params[:page].to_i

		logger.info(@data)
		post_url = "#{APP_CONFIG['api_url']}/cdr/list/exported"
		result = RestClient.post post_url, @data.to_json, content_type: :json

		@result = JSON.parse(result)
		#logger.info 'response.......' + @result.inspect
		page_start = (@result['page'] - 1) * @result['rows']
		i = 1
		@data = @result['list'].collect do |rec|
			if policy(:report).select_carrier?
				val = [
					i + page_start, 
					rec['timestamp'].present? ? Time.parse(rec['timestamp']).in_time_zone(current_user.timezone).to_s(:reporting) : '',
					rec['username'].present? ? User.find_by(username: rec['username'].downcase).name : '',
					rec['start'].present? ? Time.parse(rec['start']).in_time_zone(current_user.timezone).to_s(:reporting) : '',
					rec['end'].present? ? Time.parse(rec['end']).in_time_zone(current_user.timezone).to_s(:reporting) : '',
					rec['status'].humanize,
					rec['rows'],
					rec['link']
				]
			else 
				val = [
					i + page_start, 
					rec['timestamp'].present? ? Time.parse(rec['timestamp']).in_time_zone(current_user.timezone).to_s(:reporting) : '',
					rec['start'].present? ? Time.parse(rec['start']).in_time_zone(current_user.timezone).to_s(:reporting) : '',
					rec['end'].present? ? Time.parse(rec['end']).in_time_zone(current_user.timezone).to_s(:reporting) : '',
					rec['status'].humanize,
					rec['rows'],
					rec['link']
				]
			end
			i += 1
			val
    end

		respond_to do |format|
			format.json
		end
	end

	def ingress_pin_down
		authorize :report, :ingress_pin_down?

		include_all = params[:include_all] == '1' ? true : false

		if params[:carrier_id].present?
			if params[:ingress_trunk_id].present?
				@rate_sheets = IngressTrunk.rate_sheets_select_options(params[:carrier_id], params[:ingress_trunk_id], include_all)
				@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(params[:carrier_id], params[:ingress_trunk_id], include_all)
				@routings = IngressTrunk.routings_select_options(params[:carrier_id], params[:ingress_trunk_id], include_all)
			else
				@ingress_trunks = IngressTrunk.select_options(params[:carrier_id], include_all)
				@rate_sheets = IngressTrunk.rate_sheets_select_options(params[:carrier_id], nil, include_all)
				@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(params[:carrier_id], nil, include_all)
				@routings = IngressTrunk.routings_select_options(params[:carrier_id], nil, include_all)
			end
		else
			if params[:ingress_trunk_id].present?
				if policy(:report).select_carrier?
					@rate_sheets = IngressTrunk.rate_sheets_select_options(nil, params[:ingress_trunk_id], include_all)
					@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(nil, params[:ingress_trunk_id], include_all)
					@routings = IngressTrunk.routings_select_options(nil, params[:ingress_trunk_id], include_all)
				else
					carrier_id = current_user.carrier.id
					include_all = false
					@rate_sheets = IngressTrunk.rate_sheets_select_options(carrier_id, params[:ingress_trunk_id], include_all)
					@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(carrier_id, params[:ingress_trunk_id], include_all)
				end
			else
				if policy(:report).select_carrier?
					@ingress_trunks = IngressTrunk.select_options(nil, include_all)
					@rate_sheets = RateSheet.for_select
					@routings = Routing.for_select
					@ingress_tech_prefixes = IngressTrunk.tech_prefixes_select_options(nil, nil, include_all)					
				else
					carrier_id = current_user.carrier.id
					@ingress_trunks = IngressTrunk.select_options(carrier_id, false)
					@rate_sheets = IngressTrunk.
											rate_sheets_select_options(carrier_id, nil, false)
					@ingress_tech_prefixes = IngressTrunk.
															tech_prefixes_select_options(carrier_id, nil, false)
				end
			end
		end
	end

	def egress_pin_down
		authorize :report, :egress_pin_down?

		include_all = params[:include_all] == '1' ? true : false

		if params[:carrier_id].present?
			if params[:egress_trunk_id].present?
				@rate_sheets = EgressTrunk.rate_sheets_select_options(params[:carrier_id], params[:egress_trunk_id], include_all)
				@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(params[:carrier_id], params[:egress_trunk_id], include_all)
			else
				@egress_trunks = EgressTrunk.select_options(params[:carrier_id], include_all)
				@rate_sheets = EgressTrunk.rate_sheets_select_options(params[:carrier_id], nil, include_all)
				@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(params[:carrier_id], nil, include_all)
			end
		else
			if params[:egress_trunk_id].present?
				@rate_sheets = EgressTrunk.rate_sheets_select_options(nil, params[:egress_trunk_id], include_all)
				@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(nil, params[:egress_trunk_id], include_all)
			else
				@egress_trunks = EgressTrunk.select_options(nil, include_all)
				@rate_sheets = RateSheet.for_select
				@egress_tech_prefixes = EgressTrunk.tech_prefixes_select_options(nil, nil, include_all)
			end
		end
	end

	def save_cdr_template
		authorize :report, :save_cdr_template?

		@template = current_user.cdr_filter_templates.build(cdr_template_params)

		@template.query = Rack::Utils.parse_nested_query cdr_template_params[:query]
		@template.query.delete_if {|key, value| ['utf8', 'authenticity_token', 'format'].include?(key) }
		@response = @template.save

		@cdr_templates = current_user.cdr_filter_templates.order('is_default DESC, name ASC')

		respond_to do |format|
			format.js
		end
		
	end

	def check_template_name
    unless request.xhr?
      redirect_to '/reports/cdr_search' and return  
    end

    skip_authorization

    if params[:search_template][:name].blank?
      render 'shared/not_found'
    end
    
    render json: !current_user.cdr_filter_templates.exists?(name: params[:search_template][:name])
  end

  def username_search
  	authorize :report, :username_search?

  	users = User.where( ['(users.name LIKE :q OR users.email LIKE :q
  	                      OR users.username LIKE :q)',
  	                      { q: "%#{params[:q]}%"}] ).
  						select('users.username, users.name').all

		respond_to do |format|
		  format.js { render json: users.as_json and return}
		end
  end

	private
	def cdr_template_params
    params[:search_template].permit(:name, :description, :query)
  end

	def init_profit_post_data
		if params[:report_type].blank?
			params[:report_type] = 'orig'
		end

		Time.zone = params[:time_zone]
		@to_date_obj = Time.zone.parse(params[:to_date])
		@from_date_obj = Time.zone.parse(params[:from_date])
		@to_date = @to_date_obj.iso8601
		@from_date = @from_date_obj.iso8601
		
		group_param = 'id_group'
		
		if 'term' == params[:report_Type]
			if %w(date month year).include?(params[:term_group_by])
				group_param = 'date_group'
			end

		 	@data[group_param] = params[:term_group_by]
		else
			if %w(date month year).include?(params[:orig_group_by])
				group_param = 'date_group'
			end

			@data[group_param] = params[:orig_group_by]
		end

		@data['tzone'] = Time.now.in_time_zone(params[:time_zone]).strftime('%:z').tr(':', '.') if params[:time_zone].present?

		if policy(:report).select_carrier?
			@data['ingress_carrier_id'] = params['ingress_carrier_id'] if params['ingress_carrier_id'].present?
			@data['ingress_rate_table_id'] = params['ingress_rate_id'] if params['ingress_rate_id'].present?
			@data['routing_id'] = params['ingress_routing_id'] if params['ingress_routing_id'].present?
			#@data['egress_carrier_id'] = params['egress_carrier_id'] if params['egress_carrier_id'].present?
			@data['egress_carrier_id'] = 1
			@data['egress_trunk_id'] = params['egress_trunk_id'] if params['egress_trunk_id'].present?
			@data['egress_rate_table_id'] = params['egress_rate_id'] if params['egress_rate_id'].present?
			@data['egress_tech_prefix'] = params['egress_techprefix_id'] if params['egress_techprefix_id'].present?
		else
			@data['ingress_carrier_id'] = current_user.carrier.id
		end
		
		@data['ingress_trunk_id'] = params['ingress_trunk_id'] if params['ingress_trunk_id'].present?
		@data['ingress_tech_prefix'] = params['ingress_techprefix_id'] if params['ingress_techprefix_id'].present?		
	end

	def profit_write_xls
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		start_row = 3
		last_row = 0

		sheet.merge_cells(0, 0, 0, 8)
		sheet.merge_cells(1, 0, 1, 8)
		sheet.merge_cells(start_row, 1, start_row, 2)
		sheet.merge_cells(start_row, 0, start_row + 1, 0)
		sheet.merge_cells(start_row, 5, start_row + 1, 5)
		sheet.merge_cells(start_row, 6, start_row + 1, 6)
		sheet.merge_cells(start_row, 3, start_row, 4)
		sheet.merge_cells(start_row, 7, start_row, 8)

		(0..8).each do |i|
			sheet.column(i).width = 15
		end

		title_format = Spreadsheet::Format.new weight: 'bold', align: 'center', size: 14
		sub_title_format = Spreadsheet::Format.new align: 'center'
		header_format = Spreadsheet::Format.new weight: 'bold', align: 'center', vertical_align: 'middle'
		footer_format = Spreadsheet::Format.new weight: 'bold', align: 'center'

		sheet.row(0).height = 18
		sheet.row(0).default_format = title_format
		sheet.row(1).default_format = sub_title_format
		sheet.row(start_row).default_format = header_format
		sheet.row(start_row + 1).default_format = header_format

		if 'term' == params[:report_Type]
			report_name = 'Profit Termination Report'
		else
			report_name = 'Profit Origination Report'
		end

		#headers
		sheet.row(0).push report_name
		sheet.row(1).push "From: #{@from_date_obj.to_s(:reporting)} To: #{@to_date_obj.to_s(:reporting)}"
		sheet.row(start_row).concat [group_by_title(@data['id_group'] || @data['date_group']), 'Duration', '', 'Profit', '', 'Ingress Cost', 'Egress Cost', 'No. of Calls']
		sheet.row(start_row + 1).concat ['', 'Raw', 'Billed', 'Value', 'Percent', '', '', 'Total', 'Non-zero']
		
		last_row = start_row + 1

		#main data rows
		@result['group'].each do |group|
			last_row += 1
			
			sheet.row(last_row).default_format = sub_title_format

			sheet.row(last_row).concat [
				group_by_col_val(@data['id_group'] || @data['date_group'], group['id']), 
				group['duration'].to_f.ceil_to(2), 
				group['billtime'].to_f.ceil_to(2), 
				group['profit'], 
				group['profit_percent'],
				group['ingress_cost'],
				group['egress_cost'],
				group['calls'],
				group['nonzero']
			]
		end

		#footer
		last_row += 1
		sheet.row(last_row).default_format = footer_format
		sheet.row(last_row).concat [
			'Total', 
			@result['total_duration'].to_f.ceil_to(2), 
			@result['total_billtime'].to_f.ceil_to(2), 
			@result['total_profit'].to_f.ceil_to(2),
			@result['avg_profit_percent'].to_f.ceil_to(2),
			@result['total_ingress_cost'].to_f.ceil_to(2),
			@result['total_egress_cost'].to_f.ceil_to(2),
			@result['total_calls'],
			@result['total_nonzero']
		]

		filename = "/tmp/#{SecureRandom.hex}.xls"
		book.write filename
		filename
	end

	def profit_generate_csv(options = {})
		CSV.generate(options) do |csv|
			if 'term' == params[:report_Type]
				report_name = 'Profit Termination Report'
			else
				report_name = 'Profit Origination Report'
			end

			csv << report_name.split(' ')
			csv << ['From:', @from_date_obj.to_s(:reporting), 'To: ', @to_date_obj.to_s(:reporting)]
			csv << []
			#header row
			csv << [
				group_by_title(@data['id_group'] || @data['date_group']), 'Raw Duration', 'Raw Billed', 
				'Profit Value', 'Profit Percent', 
				'Ingress Cost', 'Egress Cost', 
				'Total Calls', 'Total Non-zero Calls'
			]
			#main data rows
			@result['group'].each do |group|
				csv << [
					group_by_col_val(@data['id_group'] || @data['date_group'], group['id']), 
					group['duration'].to_f.ceil_to(2), 
					group['billtime'].to_f.ceil_to(2), 
					group['profit'], 
					group['profit_percent'],
					group['ingress_cost'],
					group['egress_cost'],
					group['calls'],
					group['nonzero']
				]
			end

			#footer
			csv << [
				'Total', 
				@result['total_duration'].to_f.ceil_to(2), 
				@result['total_billtime'].to_f.ceil_to(2), 
				@result['total_profit'].to_f.ceil_to(2),
				@result['avg_profit_percent'].to_f.ceil_to(2),
				@result['total_ingress_cost'].to_f.ceil_to(2),
				@result['total_egress_cost'].to_f.ceil_to(2),
				@result['total_calls'],
				@result['total_nonzero']
			]
		end
	end

	def summary_write_xls
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		start_row = 3
		last_row = 0

		sheet.merge_cells(0, 0, 0, 12)
		sheet.merge_cells(1, 0, 1, 12)
		sheet.merge_cells(start_row, 0, start_row + 1, 0)
		sheet.merge_cells(start_row, 1, start_row + 1, 1)
		sheet.merge_cells(start_row, 2, start_row + 1, 2)
		sheet.merge_cells(start_row, 3, start_row + 1, 3)
		sheet.merge_cells(start_row, 4, start_row, 5)
		sheet.merge_cells(start_row, 6, start_row + 1, 6)
		sheet.merge_cells(start_row, 7, start_row + 1, 7)
		sheet.merge_cells(start_row, 8, start_row, 10)
		sheet.merge_cells(start_row, 11, start_row, 12)

		(0..12).each do |i|
			sheet.column(i).width = 15
		end

		title_format = Spreadsheet::Format.new weight: 'bold', align: 'center', size: 14
		sub_title_format = Spreadsheet::Format.new align: 'center'
		header_format = Spreadsheet::Format.new weight: 'bold', align: 'center', vertical_align: 'middle'
		footer_format = Spreadsheet::Format.new weight: 'bold', align: 'center'

		sheet.row(0).height = 18
		sheet.row(0).default_format = title_format
		sheet.row(1).default_format = sub_title_format
		sheet.row(start_row).default_format = header_format
		sheet.row(start_row + 1).default_format = header_format

		if 'term' == params[:report_Type]
			report_name = 'Summary Termination Report'
		else
			report_name = 'Summary Origination Report'
		end

		#headers
		sheet.row(0).push report_name
		sheet.row(1).push "From: #{@from_date_obj.to_s(:reporting)} To: #{@to_date_obj.to_s(:reporting)}"
		sheet.row(start_row).concat [group_by_title(@data['id_group'] || @data['date_group']), 'ASR', 'ACD', 'PDD', 'Duration', '', 'Usage(cost)', 'Avg Rate', 'No. Of Calls', '', '', 'Jurisdiction']
		sheet.row(start_row + 1).concat ['', '', '', '', 'Raw', 'Billed', '', '', 'Total', 'Non-zero', 'LRN Calls', 'Interstate', 'Intrastate']
		
		last_row = start_row + 1

		#main data rows
		@result['group'].each do |group|
			last_row += 1
			sheet.row(last_row).default_format = sub_title_format
			sheet.row(last_row).concat [
				group_by_col_val(@data['id_group'] || @data['date_group'], group['id']),
		        group['asr'],
		        group['acd'],
		        group['pdd'],
		        group['duration'].to_f.ceil_to(2),
		        group['billtime'].to_f.ceil_to(2),
		        group['cost'],
		        group['avg_rate'],
		        group['calls'],
		        group['nonzero'],
		        group['lrn_calls'],
		        group['inter_rate'].to_f.ceil_to(2),
		        group['intra_rate'].to_f.ceil_to(2)
			]
		end

		#footer
		last_row += 1
		sheet.row(last_row).default_format = footer_format
		sheet.row(last_row).concat [
				'Total', 
				@result['avg_asr'],
	      @result['avg_acd'],
	      @result['avg_pdd'],
	      @result['total_duration'].to_f.ceil_to(2),
	      @result['total_billtime'].to_f.ceil_to(2),
	      @result['total_cost'],
	      @result['avg_rate'],
	      @result['total_calls'],
	      @result['total_nonzero'],
	      @result['total_lrn_calls'],
	      @result['total_inter'].to_f.ceil_to(2),
	      @result['total_intra'].to_f.ceil_to(2)
		]

		filename = "/tmp/#{SecureRandom.hex}.xls"
		book.write filename
		filename
	end

	def summary_generate_csv(options = {})
		CSV.generate(options) do |csv|
			if 'term' == params[:report_Type]
				report_name = 'Summary Termination Report'
			else
				report_name = 'Summary Origination Report'
			end

			csv << report_name.split(' ')
			csv << ['From:', @from_date_obj.to_s(:reporting), 'To: ', @to_date_obj.to_s(:reporting)]
			csv << []
			#header row
			csv << [
				group_by_title(@data['id_group'] || @data['date_group']), 'ASR', 'ACD', 
				'PDD', 'Raw Duration', 'Billed Duration', 
				'Usage(cost)', 'Avg. Cost', 'Total Calls',
				'Total Non-zero Calls', 'Total LRN Calls',
				'Interstate Jurisdiction', 'Intrastate Jurisdiction'
			]
			#main data rows
			@result['group'].each do |group|
				csv << [
					group_by_col_val(@data['id_group'] || @data['date_group'], group['id']),
	        group['asr'],
	        group['acd'],
	        group['pdd'],
	        group['duration'].to_f.ceil_to(2),
	        group['billtime'].to_f.ceil_to(2),
	        group['cost'],
	        group['avg_rate'],
	        group['calls'],
	        group['nonzero'],
	        group['lrn_calls'],
	        group['inter_rate'].to_f.ceil_to(2),
        	group['intra_rate'].to_f.ceil_to(2)
				]
			end

			#footer
			csv << [
				'Total', 
			 	@result['avg_asr'],
	      @result['avg_acd'],
	      @result['avg_pdd'],
	      @result['total_duration'].to_f.ceil_to(2),
	      @result['total_billtime'].to_f.ceil_to(2),
	      @result['total_cost'],
	      @result['avg_rate'],
	      @result['total_calls'],
	      @result['total_nonzero'],
	      @result['total_lrn_calls'],
	      @result['total_inter'].to_f.ceil_to(2),
	      @result['total_intra'].to_f.ceil_to(2)
			]
		end
	end

	def init_did_post_data
		Time.zone = params[:time_zone]
		@to_date_obj = Time.zone.parse(params[:to_date])
		@from_date_obj = Time.zone.parse(params[:from_date])
		@to_date = @to_date_obj.iso8601
		@from_date = @from_date_obj.iso8601
		
		group_param = 'id_group'
		if %w(date month year).include?(params[:group_by])
			group_param = 'date_group'
		end

		@data[group_param] = params[:group_by]
		
		@data['tzone'] = Time.now.in_time_zone(params[:time_zone]).strftime('%:z').tr(':', '.') if params[:time_zone].present?

		if policy(:report).select_carrier?
			@data['did_carrier_id'] = params['did_carrier_id'] if params['did_carrier_id'].present?
		else
			#@data['did_carrier_id'] = current_user.carrier.id
			@data['did_carrier_id'] = 1
		end
	end

	def did_write_xls
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		start_row = 3
		last_row = 0

		sheet.merge_cells(0, 0, 0, 8)
		sheet.merge_cells(1, 0, 1, 8)
		# sheet.merge_cells(start_row, 1, start_row, 2)
		# sheet.merge_cells(start_row, 0, start_row + 1, 0)
		# sheet.merge_cells(start_row, 5, start_row + 1, 5)
		# sheet.merge_cells(start_row, 6, start_row + 1, 6)
		# sheet.merge_cells(start_row, 3, start_row, 4)
		# sheet.merge_cells(start_row, 7, start_row, 8)

		total_cols = 8
		if policy(:report).select_carrier? && 'did' == @data['id_group']
			total_cols = 10          	
    end

		(0..total_cols).each do |i|
			sheet.column(i).width = 15
			end

		title_format = Spreadsheet::Format.new weight: 'bold', align: 'center', size: 14
		sub_title_format = Spreadsheet::Format.new align: 'center'
		header_format = Spreadsheet::Format.new weight: 'bold', align: 'center', vertical_align: 'middle'
		footer_format = Spreadsheet::Format.new weight: 'bold', align: 'center'

		sheet.row(0).height = 18
		sheet.row(0).default_format = title_format
		sheet.row(1).default_format = sub_title_format
		sheet.row(start_row).default_format = header_format
		#sheet.row(start_row + 1).default_format = header_format

		report_name = 'DID Report'

		#headers
		sheet.row(0).push report_name
		sheet.row(1).push "From: #{@from_date_obj.to_s(:reporting)} To: #{@to_date_obj.to_s(:reporting)}"

		header_data = [
			group_by_title(@data['id_group'] || @data['date_group']), 
			'Total Calls',
			'Non-zero',
			'Raw Duration', 
			'Billable Duration', 
			'Cost', 
			'Avg. Channels', 
			'Avg. CPS',
			'Max. CPS'
		]

		if policy(:report).select_carrier? && 'did' == @data['id_group']
			header_data.insert(3, 'Carrier', 'Vendor')			
		end

		sheet.row(start_row).concat(header_data)
		
		#sheet.row(start_row + 1).concat ['', 'Raw', 'Billed', 'Value', 'Percent', '', '', 'Total', 'Non-zero']
		
		last_row = start_row

		#main data rows
		@result['group'].each do |group|
			last_row += 1
			
			sheet.row(last_row).default_format = sub_title_format
			group_data = [
				group_by_col_val(@data['id_group'] || @data['date_group'], group['id']),
				group['calls'],
				group['nonzero'],
				'',
				group['billtime'],
				group['cost'],
				group['avg_channels'],
				group['avg_cps'],
				group['max_channels']
			]

			if policy(:report).select_carrier? && 'did' == @data['id_group']
				group_data.insert(3, group['id']['did_carrier_name'], group['id']['did_vendor_name'])
			end

			sheet.row(last_row).concat(group_data)
		end

		#footer
		last_row += 1
		sheet.row(last_row).default_format = footer_format

		footer_data = [
			'Total', 
			@result['total_calls'], 
			@result['total_nonzero'], 
			'',
			@result['total_billtime'],
			@result['total_cost'],
			@result['avg_channels'],
			@result['avg_cps'],
			''
		]

		if policy(:report).select_carrier? && 'did' == @data['id_group']
			footer_data.insert(3, '', '')
		end

		sheet.row(last_row).concat(footer_data)

		filename = "/tmp/#{SecureRandom.hex}.xls"
		book.write filename
		filename
	end

	def did_generate_csv(options = {})
		CSV.generate(options) do |csv|
			report_name = 'DID Report'

			csv << report_name.split(' ')
			csv << ['From:', @from_date_obj.to_s(:reporting), 'To: ', @to_date_obj.to_s(:reporting)]
			csv << []
			
			#header row
			header_data = [
				group_by_title(@data['id_group'] || @data['date_group']),
				'Total Calls', 'Non-zero', 'Raw Duration', 'Billable Duration',
				'Cost', 'Avg. Channels', 'Avg. CPS', 'Max. CPS'
			]

			if policy(:report).select_carrier? && 'did' == @data['id_group']
				header_data.insert(3, 'Carrier', 'Vendor')
			end

			csv << header_data

			#main data rows
			@result['group'].each do |group|
					group_data = [
					group_by_col_val(@data['id_group'] || @data['date_group'], group['id']),
	        group['calls'],
	        group['nonzero'],
	        '',
	        group['billtime'],
	        group['cost'],
	        group['avg_channels'],
	        group['avg_cps'],
	        group['max_channels']
				]

				if policy(:report).select_carrier? && 'did' == @data['id_group']
					group_data.insert(3, group['id']['did_carrier_name'], group['id']['did_vendor_name'])
				end

				csv << group_data
			end

			#footer
			footer_data = [
				'Total',
			 	@result['total_calls'],
	      @result['total_nonzero'],
	      '',
	      @result['total_billtime'],
	      @result['total_cost'],
	      @result['avg_channels'],
	      @result['avg_cps'],
	      ''
			]

			if policy(:report).select_carrier? && 'did' == @data['id_group']
				footer_data.insert(3, '', '')
			end

			csv << footer_data
		end
	end

	def sms_write_xls
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		start_row = 3
		last_row = 0

		sheet.merge_cells(0, 0, 0, 11)
		sheet.merge_cells(1, 0, 1, 11)
		# sheet.merge_cells(start_row, 1, start_row, 2)
		# sheet.merge_cells(start_row, 0, start_row + 1, 0)
		# sheet.merge_cells(start_row, 5, start_row + 1, 5)
		# sheet.merge_cells(start_row, 6, start_row + 1, 6)
		# sheet.merge_cells(start_row, 3, start_row, 4)
		# sheet.merge_cells(start_row, 7, start_row, 8)

		total_cols = 11
		
		(0..total_cols).each do |i|
			sheet.column(i).width = 15
		end

		title_format = Spreadsheet::Format.new weight: 'bold', align: 'center', size: 14
		sub_title_format = Spreadsheet::Format.new align: 'center'
		header_format = Spreadsheet::Format.new weight: 'bold', align: 'center', vertical_align: 'middle'
		footer_format = Spreadsheet::Format.new weight: 'bold', align: 'center'

		sheet.row(0).height = 18
		sheet.row(0).default_format = title_format
		sheet.row(1).default_format = sub_title_format
		sheet.row(start_row).default_format = header_format
		#sheet.row(start_row + 1).default_format = header_format

		report_name = 'SMS Report'

		#headers
		sheet.row(0).push report_name
		sheet.row(1).push "From: #{@from_date.to_s(:reporting)} To: #{@to_date.to_s(:reporting)}"

		header_data = [
			group_by_title(params[:group_by]),
      'Total', 'Outgoing', 'Incoming', 
      'Forwarded', 'Outgoing Cost', 
      'Incoming Cost', 'Forwarded Cost', 
      'Total Cost', 'Successful', 'Failed'
		]

		sheet.row(start_row).concat(header_data)
		
		#sheet.row(start_row + 1).concat ['', 'Raw', 'Billed', 'Value', 'Percent', '', '', 'Total', 'Non-zero']
		
		last_row = start_row
		grand_total = Array.new(10, 0)
		
		#main data rows
		@sms_logs.each do |log|
			last_row += 1
			sheet.row(last_row).default_format = sub_title_format

			grand_total[0] += log.total_sms
      	grand_total[1] += log.outgoing
      	grand_total[2] += log.incoming
      	grand_total[3] += log.forwarded
      	grand_total[4] += log.outgoing_cost
      	grand_total[5] += log.incoming_cost
      	grand_total[6] += log.forwarded_cost
      	grand_total[7] += log.total_cost
      	grand_total[8] += log.successful
      	grand_total[9] += log.failed

			group_data = [
        'sms_carrier_id' == params[:group_by] ? log.company_name : log.sdate,
        log.total_sms,
        log.outgoing,
        log.incoming,
        log.forwarded,
        log.outgoing_cost,
        log.incoming_cost,
        log.forwarded_cost,
        log.total_cost,
        log.successful,
        log.failed
      ]

			sheet.row(last_row).concat(group_data)
		end

		#footer
		last_row += 1
		sheet.row(last_row).default_format = footer_format

		footer_data = ['Total'] + grand_total

		sheet.row(last_row).concat(footer_data)

		filename = "/tmp/#{SecureRandom.hex}.xls"
		book.write filename
		filename
	end

	def sms_generate_csv(options = {})
    CSV.generate(options) do |csv|
      report_name = 'SMS Report'

      csv << report_name.split(' ')
      csv << ['From:', @from_date.to_s(:reporting), 'To: ', @to_date.to_s(:reporting)]
      csv << []
      
      #header row
      header_data = [
        group_by_title(params[:group_by]),
        'Total', 'Outgoing', 'Incoming', 'Forwarded', 'Outgoing Cost', 'Incoming Cost',
        'Forwarded Cost', 'Total Cost', 'Successful', 'Failed'
      ]

      csv << header_data
      #main data rows
      grand_total = Array.new(10, 0)

      @sms_logs.each do |log|
      	grand_total[0] += log.total_sms
      	grand_total[1] += log.outgoing
      	grand_total[2] += log.incoming
      	grand_total[3] += log.forwarded
      	grand_total[4] += log.outgoing_cost
      	grand_total[5] += log.incoming_cost
      	grand_total[6] += log.forwarded_cost
      	grand_total[7] += log.total_cost
      	grand_total[8] += log.successful
      	grand_total[9] += log.failed
      	
        group_data = [
          'sms_carrier_id' == params[:group_by] ? log.company_name : log.sdate,
          log.total_sms,
          log.outgoing,
          log.incoming,
          log.forwarded,
          log.outgoing_cost,
          log.incoming_cost,
          log.forwarded_cost,
          log.total_cost,
          log.successful,
          log.failed
        ]
        csv << group_data
      end

  		#footer
  		footer_data = ['Total'] + grand_total

  		csv << footer_data
    end
  end

	
	def init_cdrsearch_post_data
		Time.zone = params[:time_zone]
		@to_date_obj = Time.zone.parse(params[:to_date])
		@from_date_obj = Time.zone.parse(params[:from_date])
		@to_date = @to_date_obj.iso8601
		@from_date = @from_date_obj.iso8601
		
		if params[:page_action] == 'export'
			@data['export'] = 'true'
			@data['username'] = current_user.username
			#@data['username'] = 'sanket'
			@data['userip'] = request.remote_ip
		end

		if policy(:report).select_carrier?
			@data['ingress_carrier_id'] = params['ingress_carrier_id'] if params['ingress_carrier_id'].present?
			@data['ingress_rate_table_id'] = params['ingress_rate_id'] if params['ingress_rate_id'].present?
			@data['egress_carrier_id'] = params['egress_carrier_id'] if params['egress_carrier_id'].present?
			@data['egress_trunk_id'] = params['egress_trunk_id'] if params['egress_trunk_id'].present?
			@data['egress_rate_table_id'] = params['egress_rate_id'] if params['egress_rate_id'].present?
			@data['egress_tech_prefix'] = params['egress_techprefix_id'] if params['egress_techprefix_id'].present?
			@data['egress_dnis'] = params['egress_dnis'] if params['egress_dnis'].present?
			@data['egress_ani'] = params['egress_ani'] if params['egress_ani'].present?
			@data['egress_response'] = params['egress_response_id'] if params['egress_response_id'].present?
			@data['ring_time'] = params['ringtime_id'] if params['ringtime_id'].present?
			@data['custom_ring_time'] = params['custom_ringtime'] if params['custom_ringtime'].present?
			allowed_sortby_cols = cdr_sortby_cols.keys
		else
			@data['ingress_carrier_id'] = current_user.carrier.id
			allowed_sortby_cols = cdr_carrier_sortby_cols.keys
		end

		@data['tzone'] = Time.now.in_time_zone(params[:time_zone]).strftime('%:z').tr(':', '.') if params[:time_zone].present?
		@data['ingress_trunk_id'] = params['ingress_trunk_id'] if params['ingress_trunk_id'].present?
		@data['ingress_tech_prefix'] = params['ingress_techprefix_id'] if params['ingress_techprefix_id'].present?
		@data['ingress_response'] = params['ingress_response_id'] if params['ingress_response_id'].present?
		@data['ingress_ani'] = params['ingress_ani'] if params['ingress_ani'].present?
		@data['ingress_dnis'] = params['ingress_dnis'] if params['ingress_dnis'].present?
		@data['call_id'] = params['callid'] if params['callid'].present?
		@data['duration'] = params['duration_id'] if params['duration_id'].present?
		
		@data['sort_by'] = params['sort_by'] if params['sort_by'].present? && allowed_sortby_cols.include?(params['sort_by'])

		if params[:page_action] == 'onscreen'
			@data['rows'] = 20
			if request.format.symbol == :xls || request.format.symbol == :csv
				@data['rows'] = 5000
			end
		end
		
		if params['sel_cols'].blank?
			if policy(:report).select_carrier?
				@data['columns'] = cdr_search_default_cols.keys.join(',')
			else
				@data['columns'] = carrier_cdr_search_default_cols.keys.join(',')
			end
		else
			unless policy(:report).select_carrier?
			  valid_cols = cdr_columns_select(false, false).keys
			  params['sel_cols'] = valid_cols & params['sel_cols']
			end
			
			@data['columns'] = params['sel_cols'].join(',')
		end
	end
	
  def cdr_search_write_xls
		book = Spreadsheet::Workbook.new
		sheet = book.create_worksheet
		start_row = 3
		last_row = 0
		
		col_order = @data['columns'].split(',')
		#columns_count = @result['cdrs'][0].keys.size
		columns_count = col_order.size

		sheet.merge_cells(0, 0, 0, columns_count)
		sheet.merge_cells(1, 0, 1, columns_count)
		sheet.merge_cells(2, 0, 2, columns_count)

		columns_count.times do |i|
			sheet.column(i).width = 15
		end

		title_format = Spreadsheet::Format.new weight: 'bold', align: 'left', size: 14
		sub_title_format = Spreadsheet::Format.new align: 'left'
		header_format = Spreadsheet::Format.new weight: 'bold', align: 'center', vertical_align: 'middle'

		sheet.row(0).height = 18
		sheet.row(0).default_format = title_format
		sheet.row(1).default_format = sub_title_format
		sheet.row(start_row).default_format = header_format
		sheet.row(start_row + 1).default_format = header_format

		report_name = 'CDR Search Report'

		#headers
		sheet.row(0).push report_name
		sheet.row(1).push "From: #{@from_date_obj.to_s(:reporting)} To: #{@to_date_obj.to_s(:reporting)}"
		sheet.row(2).push 'Showing top 5,000 records'
		if policy(:report).select_carrier?
		  columns_select = cdr_columns_select(true, false)
		else
		  columns_select = cdr_columns_select(false, false)
		end 

		sheet.row(start_row).concat col_order.collect {|colkey| columns_select[colkey]}
		
		last_row = start_row + 1

		#main data rows
		@result['cdrs'].each do |rec|
			last_row += 1
			sheet.row(last_row).default_format = sub_title_format
			sheet.row(last_row).concat col_order.collect {|colkey| cdr_search_format_value(colkey, rec[colkey])}
		end

		filename = "/tmp/#{SecureRandom.hex}.xls"
		book.write filename
		filename
	end

	def cdr_search_generate_csv(options = {})
		col_order = @data['columns'].split(',')

		CSV.generate(options) do |csv|
			report_name = 'CDR Search Report'

			csv << report_name.split(' ')
			csv << ['From:', @from_date_obj.to_s(:reporting), 'To: ', @to_date_obj.to_s(:reporting)]
			csv << ['Showing top 5,000 records']
			csv << []
			
			#header row
			if policy(:report).select_carrier?
			  columns_select = cdr_columns_select(true, false)
			else
			  columns_select = cdr_columns_select(false, false)
			end 
			csv << col_order.collect { |colkey| columns_select[colkey] }
			
			#main data rows
			@result['cdrs'].each do |rec|
				csv << col_order.collect { |colkey| cdr_search_format_value(colkey, rec[colkey]) }
			end
		end
	end

	def init_cdrlogs_post_data
		Time.zone = params[:time_zone]
		@to_date_obj = Time.zone.parse(params[:to_date])
		@from_date_obj = Time.zone.parse(params[:from_date])
		@data['end'] = @to_date_obj.iso8601
		@data['start'] = @from_date_obj.iso8601
		@data['rows'] = 25
		if policy(:report).select_carrier?
			@data['username'] = params[:username]
		else
			@data['username'] = current_user.username
		end
	end

	def rest_resource(url)
		RestClient::Resource.new url,
			timeout: APP_CONFIG['app_timeout'],
		  open_timeout: APP_CONFIG['app_timeout']
	end
end
