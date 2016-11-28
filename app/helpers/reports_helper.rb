module ReportsHelper
	def group_by_title(group_name)
		return 	case group_name
            when 'did_vendor_id'
              'Vender Name'
            when 'did'
              'DID'
            when 'did_carrier_id'
              'Carrier'
            when 'sms_carrier_id'
              'Carrier'
	    		 	when 'ingress_trunk_id'
	    				'Ingress Trunk'
	    			when 'ingress_carrier_id'
	            'Ingress Carrier'
	          when 'egress_trunk_id'
	            'Egress Trunk'
	          when 'egress_carrier_id'
	            'Egress Carrier'
            when 'date'
              'Date'
            when 'month'
              'Month'
            when 'year'
              'Year'
	          else
	            ''
	          end
	end

	def group_by_col_val(group_name, id_row)
		return 	case group_name
            when 'did_vendor_id'
              id_row['did_vendor_name']
            when 'did'
              id_row['did']
            when 'did_carrier_id'
              id_row['did_carrier_name']
	    		 	when 'ingress_trunk_id'
	    				id_row['ingress_trunk_name']
	    			when 'ingress_carrier_id'
	            id_row['ingress_carrier_name']
	          when 'egress_trunk_id'
	            id_row['egress_trunk_name']
	          when 'egress_carrier_id'
	            id_row['egress_carrier_name']
            when 'date', 'month', 'year'
              id_row['calendar']
	          else
	            ''
	          end
	end

	def date_range_options
		[
			['Current Hour', 1],
			['Previous Hour', 2],
			['Today', 0],
			['Yesterday', 3],
			['Current Week', 4],
			['Previous Week', 5],
			['Current Month', 6],
			['Previous Month', 7],
			['Current Year', 8],
			['Previous Year', 9]
		]
	end

	def profit_group_by_options1(for_admin = true)
    if(for_admin) 
      ingress_options = [
        ['Ingress Carrier', 'ingress_carrier_id'],
        ['Ingress Trunk', 'ingress_trunk_id']
      ]
    else
      ingress_options = [
        ['Ingress Trunk', 'ingress_trunk_id']
      ]      
    end

		{
			'By Ingress': ingress_options,
			'By Date':  [
				['Year', 'year'],
				['Month', 'month'],
				['Day', 'date']
			]
		}
	end

	def profit_group_by_options2
		{
			'By Egress': [
				['Egress Carrier', 'egress_carrier_id'],
				['Egress Trunk', 'egress_trunk_id']
			],
			'By Date':  [
				['Year', 'year'],
				['Month', 'month'],
				['Day', 'date']
			]

		}
	end

  def did_group_by_options(for_admin = true)
    if(for_admin) 
      did_options = [
        ['Carrier', 'did_carrier_id'],
        ['Vendor', 'did_vendor_id'],
        ['DID', 'did']
      ]
    else
       did_options = [
        ['DID', 'did']
      ]  
    end

    {
      'By': did_options,
      'By Date':  [
        ['Year', 'year'],
        ['Month', 'month'],
        ['Day', 'date']
      ]
    }
  end

  def sms_group_by_options(for_admin = true)
    options = []
    
    if(for_admin) 
      options << ['Carrier', 'sms_carrier_id']
    end
    
    options << ['Day', 'date']
    options << ['Month', 'month']
    options << ['Year', 'year']

    options  
  end

	def sip_responses
    [
      ["182 Queued","182"],
      ["183 Session Progress","183"],
      ["200 OK","200"],
      ["300 Multiple Choices","300"],
      ["301 Moved Permanently","301"],
      ["302 Moved Temporarily","302"],
      ["305 Use Proxy","305"],
      ["380 Alternative Service","380"],
      ["400 Bad Request","400"],
      ["401 Unauthorized","401"],
      ["402 Payment Required","402"],
      ["403 Forbidden","403"],
      ["404 Not Found","404"],
      ["405 Method Not Allowed","405"],
      ["406 Not Acceptable","406"],
      ["407 Proxy Authentication Required","407"],
      ["408 Request Timeout","408"],
      ["410 Gone","410"],
      ["413 Request Entity Too Large","413"],
      ["414 Request-URI Too Long","414"],
      ["415 Unsupported Media Type","415"],
      ["416 Unsupported URI Scheme","416"],
      ["420 Bad Extension","420"],
      ["421 Extension Required","421"],
      ["423 Interval Too Brief","423"],
      ["480 Temporarily Unavailable","480"],
      ["481 Call/Transaction Does Not Exist","481"],
      ["483 Too Many Hops","483"],
      ["484 Address Incomplete","484"],
      ["485 Ambiguous","485"],
      ["486 Busy Here","486"],
      ["487 Request Terminated","487"],
      ["488 Not Acceptable Here","488"],
      ["491 Request Pending","491"],
      ["493 Undecipherable","493"],
      ["500 Server Internal Error","500"],
      ["501 Not Implemented","501"],
      ["502 Bad Gateway","502"],
      ["503 Service Unavailable","503"],
      ["504 Server Time-out","504"],
      ["505 Version Not Supported","505"],
      ["513 Message Too Large","513"],
      ["600 Busy Everywhere","600"],
      ["603 Decline","603"],
      ["604 Does Not Exist Anywhere","604"],
      ["606 Not Acceptable","606"]
    ]

  end

  def cdr_columns_select(all=false, sort=true)
    if(all)
      if sort
        cdr_search_default_cols.merge(cdr_columns_select_hash.sort_by{|k,v| v}.to_h)
      else
        cdr_search_default_cols.merge(cdr_columns_select_hash)
      end
    else
      if sort
        carrier_cdr_search_default_cols.merge(cdr_carrier_columns_select_hash.sort_by{|k,v| v}.to_h)
      else
        carrier_cdr_search_default_cols.merge(cdr_carrier_columns_select_hash)
      end
    end
  end

  def cdr_sortby_cols
    {
      'ingress_carrier_id' => 'Ingress Carrier ID',
      'ingress_trunk_id' => 'Ingress Trunk ID',
      'ingress_rate_table_id' => 'Ingress Rate Table ID',
      'ingress_tech_prefix' => 'Ingress Tech Prefix',
      'response_ingress' => 'Response Ingress',
      'egress_carrier_id' => 'Egress Carrier ID',
      'egress_trunk_id' => 'Egress Trunk ID',
      'egress_rate_table_id' => 'Egress Rate Table ID',
      'egress_tech_prefix' => 'Egress Tech Prefix',
      'response_egress' => 'Response Egress',
      'orig_ani' => 'Origin ANI',
      'orig_dst_number' => 'Orig Dst Number',
      'call_id' => 'Call ID',
      'term_ani' => 'Term ANI',
      'term_dst_number' => 'Term Dst Number',
      'ring_time' => 'Ring Time',
      'duration' => 'Duration',
      'start_time' => 'Time Start'
    }
  end

  def cdr_carrier_sortby_cols
    {
      'ingress_trunk_id' => 'Ingress Trunk ID',
      'ingress_rate_table_id' => 'Ingress Rate Table ID',
      'ingress_tech_prefix' => 'Ingress Tech Prefix',
      'response_ingress' => 'Response Ingress',
      'orig_ani' => 'Origin ANI',
      'orig_dst_number' => 'Orig Dst Number',
      'call_id' => 'Call ID',
      'ring_time' => 'Ring Time',
      'duration' => 'Duration',
      'start_time' => 'Time Start'
    }
  end

  def cdr_carrier_columns_select_hash
    # \"(.*?)\" => \"(.*?)\"
    # ["\2", "\1"]
    {
      'reg_user' => 'Reg User',
      'orig_ip' => 'Orig IP',
      'end_time' => 'Time End',
      'answer_time' => 'Time Answer',
      'call_id' => 'Call ID',
      'response_ingress' => 'Response Ingress',
      'ingress_rate_type' => 'Ingress Rate Type',
      'lrn_number' => 'LRN Number',
      'pdd' => 'PDD',
      'ring_time' => 'Ring Time',
      'ingress_trunk_id' => 'Ingress Trunk ID',
      'ingress_trunk_name' => 'Ingress Trunk Name',
      'orig_code_name' => 'Orig Code Name',
      'orig_code_country' => 'Orig Code Country',
      'orig_code' => 'Orig Code',
      'ingress_rate' => 'Ingress Rate',
      'ingress_billtime' => 'Ingress Billtime',
      'ingress_rate_id' => 'Ingress Rate ID',
      'ingress_rate_table_id' => 'Ingress Rate Table ID',
      'ingress_rate_table_name' => 'Ingress Rate Table Name',
      'ingress_lrn' => 'Ingress LRN',
      'ingress_carrier_name' => 'Ingress Carrier Name',
      'ingress_bill_increment' => 'Ingress Bill Increment',
      'ingress_bill_start' => 'Ingress Bill Start',
      'orig_codecs' => 'Origin Codecs',
      'ingress_connect_fee' => 'Ingress Connect Fee',
      'surcharge_1' => 'Surcharge',
      'surcharge_1_id' => 'Surcharge 1 ID',
      'surcharge_2' => 'Surcharge 2',
      'surcharge_2_id' => 'Surcharge 2 ID',
      'surcharge_3' => 'Surcharge 3',
      'surcharge_3_id' => 'Surcharge 3 ID',
      'ingress_tech_prefix' => 'Ingress Tech Prefix'
    }
  end

  def cdr_columns_select_hash
    # \"(.*?)\" => \"(.*?)\"
    # ["\2", "\1"]
    {
      'start_time' => 'Time Start',
      'end_time' => 'Time End',

      'orig_ani' => 'Origin ANI',
      'orig_dst_number' => 'Orig Dst Number',

      'ingress_rate' => 'Ingress Rate',
      'ingress_rate_type' => 'Ingress Rate Type',
      'ingress_rate_id' => 'Ingress Rate ID',
      'ingress_rate_table_id' => 'Ingress Rate Table ID',
      'ingress_rate_table_name' => 'Ingress Rate Table Name',

      'egress_trunk_id' => 'Egress Trunk ID',
      'egress_trunk_name' => 'Egress Trunk Name',
      'egress_rate' => 'Egress Rate',
      'egress_rate_type' => 'Egress Rate Type',
      'egress_rate_id' => 'Egress Rate ID',
      'egress_rate_table_id' => 'Egress Rate Table ID',
      'egress_rate_table_name' => 'Egress Rate Table Name',
      
      'margin_percent' => 'Margin %',

      'reg_user' => 'Reg User',
      'term_ani' => 'Term ANI',
      'orig_ip' => 'Orig IP',
      'term_dst_number' => 'Term Dst Number?',
      'term_ip' => 'Term IP',
      'answer_time' => 'Time Answer',
      'duration' => 'Duration',
      'routing_id' => 'Routing ID',
      'routing_name' => 'Routing Name',
      'call_id' => 'Call ID',
      'release_side' => 'Release Side',
      'response_egress' => 'Response Egress',
      'response_ingress' => 'Response Ingress',
      'release_cause' => 'Release Cause',
      'lrn_number' => 'LRN Number',
      'lrn_source' => 'LRN Source',
      'pdd' => 'PDD',
      'ring_time' => 'Ring Time',
      'processing' => 'Processing',
      'ingress_trunk_id' => 'Ingress Trunk ID',
      'ingress_trunk_name' => 'Ingress Trunk Name',
      'term_code' => 'Term Code',
      'term_code_name' => 'Term Code Name',
      'term_code_country' => 'Term Code Country',
      'orig_code_name' => 'Orig Code Name',
      'orig_code_country' => 'Orig Code Country',
      'orig_code' => 'Orig Code',
      'ingress_billtime' => 'Ingress Billtime',
      'egress_billtime' => 'Egress Billtime',
      'egress_lrn' => 'Egress LRN',
      'ingress_lrn' => 'Ingress LRN',
      'ingress_bill_increment' => 'Ingress Bill Increment',
      'ingress_bill_start' => 'Ingress Bill Start',
      'egress_bill_increment' => 'Egress Bill Increment',
      'egress_bill_start' => 'Egress Bill Start',
      'orig_codecs' => 'Origin Codecs',
      'term_codecs' => 'Term Codecs',
      'ingress_connect_fee' => 'Ingress Connect Fee',
      'egress_connect_fee' => 'Egress Connect Fee',
      'surcharge_1' => 'Surcharge',
      'surcharge_1_id' => 'Surcharge 1 ID',
      'surcharge_2' => 'Surcharge 2',
      'surcharge_2_id' => 'Surcharge 2 ID',
      'surcharge_3' => 'Surcharge 3',
      'surcharge_3_id' => 'Surcharge 3 ID',
      'egress_tech_prefix' => 'Egress Tech Prefix',
      'ingress_tech_prefix' => 'Ingress Tech Prefix',
    }
  end

  def cdr_search_default_cols
    {
      'ingress_carrier_id' => 'Ingress Carrier ID',
      'ingress_carrier_name' => 'Ingress Carrier Name',
      'egress_carrier_id' => 'Egress Carrier ID',
      'egress_carrier_name' => 'Egress Carrier Name',
      'ingress_cost' => 'Ingress Cost',
      'egress_cost' => 'Egress Cost',
      'start_time' => 'Time Start',

    }
  end

  def carrier_cdr_search_default_cols
    {
      'start_time' => 'Time Start',
      'orig_ani' => 'Origin ANI',
      'orig_dst_number' => 'Orig Dst Number',
      'duration' => 'Duration',
      'ingress_cost' => 'Ingress Cost'
    }
  end

  def cdr_search_format_value(key, value)
    if %w(start_time answer_time end_time).include?(key)
      Time.zone.at(value/1000).to_s(:db)
    elsif %w(ingress_cost egress_cost ingress_rate egress_rate).include?(key)
      value.to_f.ceil_to(2)
    else
      value
    end
  end

  def downloaded_filename(label, ext = '')
    ext = ".#{ext}" if ext.present?

    "#{label} #{Time.now.strftime('%Y%m%d-%H%M')}#{ext}"
  end

end
