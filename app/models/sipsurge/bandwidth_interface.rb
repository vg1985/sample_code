require 'ruby-bandwidth'

module Sipsurge
  class BandwidthInterface
    DEFAULT_QTY_PARAM = 100
              
      class << self
      def sms_settings
        Setting.find_by(uid: 'sms')
      end

      def sms_client
        client = Bandwidth::Client.new(user_id: sms_settings.sms_user_id,
                                       api_token: sms_settings.sms_api_token,
                                       api_secret: sms_settings.sms_api_secret)
      end

      def local_settings
        Setting.find_by(uid: 'bandwidth_api_local')
      end

      def tf_settings
        Setting.find_by(uid: 'bandwidth_api_tf')
      end
      
      def local_base_url
        "#{local_settings.bandwidth_url}"
      end    

      def tf_base_url
        "#{tf_settings.bandwidth_url}"
      end
      
      def parse_response(response)
        Hash.from_xml(response)  
      end
          
      def available_numbers(type, params)
        if 'local' == type
          params[:quantity] = local_settings.bandwidth_search_max_numbers || DEFAULT_QTY_PARAM
          client = RestClient::Resource.new "#{local_base_url}/accounts/#{local_settings.bandwidth_account}/availableNumbers?#{params.to_query}", local_settings.bandwidth_username, local_settings.bandwidth_password
        else
          params[:quantity] = tf_settings.bandwidth_search_max_numbers || DEFAULT_QTY_PARAM
          client = RestClient::Resource.new "#{tf_base_url}/accounts/#{tf_settings.bandwidth_account}/availableNumbers?#{params.to_query}", tf_settings.bandwidth_username, tf_settings.bandwidth_password
        end
        
        begin
          response = client.get(content_type: 'application/xml')
          response = parse_response(response)
        rescue => e
          response = parse_response(e.response)
          #{"SearchResult"=>{"Error"=>{"Code"=>"4010", "Description"=>"The length of the search criteria 'Area Code' is not valid, the acceptable length is 3 characters."}}} 
        end        
        
        #{"SearchResult"=>{"ResultCount"=>"5", "TelephoneNumberList"=>{"TelephoneNumber"=>["9192059184", "9192059231", "9192059630", "9192059582", "9192300455"]}}}
        #{"SearchResult"=> nil}
        if response["SearchResult"].blank?
          return {count: 0}
        elsif response["SearchResult"]["Error"].present?
          return {count: -1, errObject: response["SearchResult"]["Error"]}
        else
          return {count: response["SearchResult"]["ResultCount"].to_i, numbers: response["SearchResult"]["TelephoneNumberList"]["TelephoneNumber"]}
        end
        
      end

      def release(type, numbers, name)
        data = build_release_xml(numbers, name)

        if 'local' == type
          client = RestClient::Resource.new("#{local_base_url}/accounts/#{local_settings.bandwidth_account}/disconnects", 
                  local_settings.bandwidth_username, local_settings.bandwidth_password)
        else
          client = RestClient::Resource.new("#{tf_base_url}/accounts/#{tf_settings.bandwidth_account}/disconnects", 
                  tf_settings.bandwidth_username, tf_settings.bandwidth_password)
        end
        
        begin
          response = client.post(data, content_type: 'application/xml')
          response = parse_response(response)
          order = response["DisconnectTelephoneNumberOrderResponse"]["orderRequest"]
          #{"DisconnectTelephoneNumberOrderResponse"=>{"orderRequest"=>{"Name"=>"Release#5", "OrderCreateDate"=>"2015-06-16T18:27:50.086Z", "id"=>"2c7f57e6-18ee-4de5-80bd-6a2bde4e525f", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["8886652516", "8886656336"]}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"RECEIVED"}}
          #{"DisconnectTelephoneNumberOrderResponse"=>{"orderRequest"=>{"Name"=>"Carrier#5-release", "OrderCreateDate"=>"2015-06-27T16:47:51.226Z", "id"=>"ad52fb98-1bbf-4edb-bc7f-7609a75335c1", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>"8889508330"}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"RECEIVED"}}
          output = {  :status => :success,
                      :order => {
                        :provider_order_id => order["id"], 
                        :name => order["Name"], 
                        :provider_create_date => order["OrderCreateDate"],
                        :dids => response["DisconnectTelephoneNumberOrderResponse"]["orderRequest"]["DisconnectTelephoneNumberOrderType"]["TelephoneNumberList"]["TelephoneNumber"],
                        :provider_status =>  response["DisconnectTelephoneNumberOrderResponse"]["OrderStatus"]
                      }
                    }        
        rescue => e
          #response = parse_response(e.message)

          output = {:status => :error, :error => response}    
        end

        puts "Response from order...." + response.inspect
        output
      end

      def release_followup(order)
        if 'local' == order.did_transaction_type
          client = RestClient::Resource.new "#{local_base_url}/accounts/#{local_settings.bandwidth_account}/disconnects/#{order.provider_order_id}", local_settings.bandwidth_username, local_settings.bandwidth_password
        else
          client = RestClient::Resource.new "#{tf_base_url}/accounts/#{tf_settings.bandwidth_account}/disconnects/#{order.provider_order_id}", tf_settings.bandwidth_username, tf_settings.bandwidth_password
        end
        

        begin
          response = client.get(content_type: 'application/xml')
          response = parse_response(response)
          response = response["DisconnectTelephoneNumberOrderResponse"]
          #{"DisconnectTelephoneNumberOrderResponse"=>{"ErrorList"=>{"Error"=>[{"Code"=>"5006", "Description"=>"Telephone number could not be disconnected since it is not associated with your account", "TelephoneNumber"=>"8886656336"}, {"Code"=>"5006", "Description"=>"Telephone number could not be disconnected since it is not associated with your account", "TelephoneNumber"=>"8886652516"}]}, "orderRequest"=>{"Name"=>"Release#5", "OrderCreateDate"=>"2015-06-16T18:27:50.086Z", "id"=>"2c7f57e6-18ee-4de5-80bd-6a2bde4e525f", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["8886652516", "8886656336"]}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"FAILED"}}
          #{"DisconnectTelephoneNumberOrderResponse"=>{"DisconnectedTelephoneNumberList"=>{"TelephoneNumber"=>"9102424707"}, "orderRequest"=>{"Name"=>"Release#5", "OrderCreateDate"=>"2015-06-17T16:30:01.503Z", "id"=>"81952f0a-c8f2-4c54-9fd6-a06ce2b8579a", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>"9102424707"}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"COMPLETE"}}
          #{"DisconnectedTelephoneNumberList"=>{"TelephoneNumber"=>"8889410053"}, "ErrorList"=>{"Error"=>{"Code"=>"5006", "Description"=>"Telephone number could not be disconnected since it is not associated with your account", "TelephoneNumber"=>"8889410055"}}, "orderRequest"=>{"Name"=>"Testingg Partial", "OrderCreateDate"=>"2015-06-30T17:01:28.969Z", "id"=>"1c1c6255-c3fd-4cc3-8534-0777e4b6492b", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["8889410053", "8889410055"]}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"PARTIAL"}
          #{"DisconnectedTelephoneNumberList"=>{"TelephoneNumber"=>["8889431208", "888942232323"]}, "ErrorList"=>{"Error"=>{"Code"=>"5006", "Description"=>"Telephone number could not be disconnected since it is not associated with your account", "TelephoneNumber"=>"8889508330"}}, "orderRequest"=>{"Name"=>"Testingg Multiple", "OrderCreateDate"=>"2015-06-30T17:06:14.529Z", "id"=>"8344c5ce-e118-46f8-97a6-0977cfc54dd3", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["8889431208", "8889508330", "888942232323"]}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"PARTIAL"} 
        rescue => e
          response = {"OrderStatus" => 'Exception', "message" => parse_response(e.to_s)}
        end  

        puts "Response from order...." + response.inspect
        response
      end

      def order(type, numbers, order_id, name)
      	#numbers = ["8889410053", "8889431208"]
        #numbers << "8889431208"
        data = build_purchase_xml(type, numbers, order_id, name) 

         if 'local' == type
          client = RestClient::Resource.new("#{local_base_url}/accounts/#{local_settings.bandwidth_account}/orders", 
                  local_settings.bandwidth_username, local_settings.bandwidth_password)
        else
           client = RestClient::Resource.new("#{tf_base_url}/accounts/#{tf_settings.bandwidth_account}/orders", 
                  tf_settings.bandwidth_username, tf_settings.bandwidth_password)
        end

        begin
          response = client.post(data, content_type: 'application/xml')
          response = parse_response(response)
          order = response["OrderResponse"]["Order"]
          #{"OrderResponse"=>{"Order"=>{"CustomerOrderId"=>"1000", "Name"=>"Carrier#5-buy", "OrderCreateDate"=>"2015-06-05T20:37:16.528Z", "BackOrderRequested"=>"false", "id"=>"603b49a2-1c24-41ca-9fbb-6a112bb1dc30", "ExistingTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["9102424729", "9102424737", "9102424707"]}}, "PartialAllowed"=>"true", "SiteId"=>"232"}, "OrderStatus"=>"RECEIVED"}
          output = {  :status => :success,
                      :order => {
                        :sipsurge_order_id => order["CustomerOrderId"], 
                        :provider_order_id => order["id"], 
                        :name => order["Name"], 
                        :provider_create_date => order["OrderCreateDate"],
                        :dids => order["ExistingTelephoneNumberOrderType"]["TelephoneNumberList"]["TelephoneNumber"],
                        :provider_status =>  response["OrderResponse"]["OrderStatus"]
                      }
                    }
        rescue => e
          response = parse_response(e.response)
          order = response["OrderResponse"]["Order"]
          #{"OrderResponse"=>{"ErrorList"=>{"Error"=>{"Code"=>"5016", "Description"=>"The SiteId submitted is invalid."}}, "Order"=>{"CustomerOrderId"=>"1000", "Name"=>"Carrier#5-buy", "OrderCreateDate"=>"2015-06-05T20:05:34.567Z", "BackOrderRequested"=>"false", "ExistingTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>"9102424707"}}, "PartialAllowed"=>"true", "SiteId"=>"2320"}}}
          output = {  :status => :error,
                      :order => {
                        :sipsurge_order_id => order["CustomerOrderId"], 
                        :provider_order_id => order["id"], 
                        :name => order["Name"], 
                        :provider_create_date => order["OrderCreateDate"],
                        :dids => order["ExistingTelephoneNumberOrderType"]["TelephoneNumberList"]["TelephoneNumber"],
                        :provider_status =>  nil
                      },
                      :error => response["OrderResponse"]["ErrorList"]["Error"]
                    }    
        end   

        #puts "Response from order...." + response.inspect
        output
      end

      def order_followup(order)
        if 'local' == order.did_transaction_type
          client = RestClient::Resource.new "#{local_base_url}/accounts/#{local_settings.bandwidth_account}/orders/#{order.provider_order_id}", local_settings.bandwidth_username, local_settings.bandwidth_password
        else
           client = RestClient::Resource.new "#{tf_base_url}/accounts/#{tf_settings.bandwidth_account}/orders/#{order.provider_order_id}", tf_settings.bandwidth_username, tf_settings.bandwidth_password
        end
        #client = RestClient::Resource.new "#{base_url}/accounts/5000335/orders/bbcb1c38-7f0f-40ce-843e-7c473e4e7d5e", settings.bandwidth_username, settings.bandwidth_password
        
        begin
          response = client.get(content_type: 'application/xml')
          response = parse_response(response)
          response = response["OrderResponse"]
          #{"OrderResponse"=>{"CompletedQuantity"=>"1", "CreatedByUser"=>"audacity_user", "LastModifiedDate"=>"2015-06-05T20:10:52.885Z", "OrderCompleteDate"=>"2015-06-05T20:10:52.885Z", "Order"=>{"CustomerOrderId"=>"1000", "Name"=>"Carrier#5-buy", "OrderCreateDate"=>"2015-06-05T20:10:52.831Z", "PeerId"=>"500793", "BackOrderRequested"=>"false", "ExistingTelephoneNumberOrderType"=>nil, "PartialAllowed"=>"true", "SiteId"=>"232"}, "OrderStatus"=>"COMPLETE", "CompletedNumbers"=>{"TelephoneNumber"=>{"FullNumber"=>"9102424707"}}, "FailedQuantity"=>"0"}}
          #{"OrderResponse"=>{"CompletedQuantity"=>"2", "CreatedByUser"=>"audacity_user", "ErrorList"=>{"Error"=>{"Code"=>"5005", "Description"=>"The telephone number is unavailable for ordering", "TelephoneNumber"=>"9102424707"}}, "FailedNumbers"=>{"FullNumber"=>"9102424707"}, "LastModifiedDate"=>"2015-06-05T20:37:16.578Z", "OrderCompleteDate"=>"2015-06-05T20:37:16.578Z", "Order"=>{"CustomerOrderId"=>"1000", "Name"=>"Carrier#5-buy", "OrderCreateDate"=>"2015-06-05T20:37:16.528Z", "PeerId"=>"500793", "BackOrderRequested"=>"false", "ExistingTelephoneNumberOrderType"=>nil, "PartialAllowed"=>"true", "SiteId"=>"232"}, "OrderStatus"=>"PARTIAL", "CompletedNumbers"=>{"TelephoneNumber"=>[{"FullNumber"=>"9102424729"}, {"FullNumber"=>"9102424737"}]}, "FailedQuantity"=>"1"}}
          #{"OrderResponse"=>{"CompletedQuantity"=>"0", "CreatedByUser"=>"audacity_user", "ErrorList"=>{"Error"=>[{"Code"=>"5005", "Description"=>"The telephone number is unavailable for ordering", "TelephoneNumber"=>"9102424729"}, {"Code"=>"5005", "Description"=>"The telephone number is unavailable for ordering", "TelephoneNumber"=>"9102424737"}]}, "FailedNumbers"=>{"FullNumber"=>["9102424729", "9102424737"]}, "LastModifiedDate"=>"2015-06-06T19:14:50.785Z", "OrderCompleteDate"=>"2015-06-06T19:14:50.785Z", "Order"=>{"CustomerOrderId"=>"2015-06-07-1009", "Name"=>"Carrer#5-purchase", "OrderCreateDate"=>"2015-06-06T19:14:50.745Z", "PeerId"=>"500793", "BackOrderRequested"=>"false", "ExistingTelephoneNumberOrderType"=>nil, "PartialAllowed"=>"true", "SiteId"=>"232"}, "OrderStatus"=>"FAILED", "FailedQuantity"=>"2"}}
        rescue => e
          response = { 'OrderStatus' => 'Exception',
                        'message' => parse_response(e.to_s) }
        end

        puts 'Response from order....' + response.inspect
        response
      end

      def order_additional_info(response)

        completed_numbers = Array.new
        failed_numbers = Array.new
        errors = Array.new

        if response["CompletedNumbers"].present?
          if response["CompletedNumbers"]["TelephoneNumber"].is_a?(Array)
            response["CompletedNumbers"]["TelephoneNumber"].each do |tn|
              completed_numbers << tn["FullNumber"]
            end
          else
            completed_numbers << response["CompletedNumbers"]["TelephoneNumber"]["FullNumber"]
          end
        end

        if response["FailedNumbers"].present?
          if response["FailedNumbers"]["FullNumber"].is_a?(Array)
            response["FailedNumbers"]["FullNumber"].each do |tn|
              failed_numbers << tn
            end
          else
            failed_numbers << response["FailedNumbers"]["FullNumber"]
          end
        end
          
        if response["ErrorList"].present?
          errors = response["ErrorList"]["Error"]
          unless errors.is_a?(Array)
            errors = [errors]
          end
        end

        message = response["message"]
        
        {completed_numbers: completed_numbers, failed_numbers: failed_numbers, errors: errors, message: message}
      end

      def list_messages
        Bandwidth::Message.list(sms_client)
      end

      #[{:id=>"m-ywfllwoioq3e6trp7v73gly"}, {:error=>#<StandardError: The number +919582891722 is restricted and cannot be used to send message.>}]
      #[{:error=>#<StandardError: The number +919711199610 is restricted and cannot be used to send message.>}, {:error=>#<StandardError: The number +919582891722 is restricted and cannot be used to send message.>}]
      #[{:id=>"m-f6uaoebrgiz4vlfgexrkl4a"}, {:error=>#<StandardError: The number +919582891722 is restricted and cannot be used to send message.>}, {:error=>#<StandardError: The number +919582891722 is restricted and cannot be used to send message.>}]
      def send_sms(from, to, text)
        data = []
        to = [to] unless to.is_a?(Array)
        
        to.each do |r|
          data << {from: from, to: r, text: text}
        end

        r = Bandwidth::Message.create(sms_client, data)
        Rails.logger.info('API Response...' + r.inspect)

        response = []
        errors = 0; success = 0

        r.each do |hsh|
          if hsh.keys.first == :error
            response << {error: hsh[:error].to_s}
            errors += 1
          else 
            response << hsh
            success += 1
          end
        end

        if errors == to.size
          status = 'failed'
        elsif success == to.size
          status = 'success'
        else
          status = 'partial success'
        end

        [status, response, success]
      end
    end

    private

    def self.build_purchase_xml(type, numbers, order_id, name)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      
      xml.instruct! :xml, :encoding => "UTF-8"
      
      xml.Order do |p|
        p.Name name
        p.PartialAllowed "true"
        
        if "local" == type
          p.accountid  local_settings.bandwidth_account
          p.SiteId local_settings.bandwidth_location  
        else
          p.accountid  tf_settings.bandwidth_account
          p.SiteId tf_settings.bandwidth_location
        end

        order_id = order_id || Order.generate_order_id

        p.CustomerOrderId order_id
        
        xml.ExistingTelephoneNumberOrderType do |e|
          xml.TelephoneNumberList do |t|
            numbers.each do |number|
              t.TelephoneNumber number
            end
          end
        end
      end
      puts xml.target!
      xml.target!
    end

    def self.build_release_xml(numbers, name)
      xml = Builder::XmlMarkup.new( :indent => 2 )

      xml.instruct! :xml, :encoding => "UTF-8"
      
      xml.DisconnectTelephoneNumberOrder do |p|
        p.Name name
        xml.DisconnectTelephoneNumberOrderType do |d|
          xml.TelephoneNumberList do |t|
            numbers.each do |number|
              t.TelephoneNumber number
            end
          end
        end
      end
      puts xml.target!
      xml.target!
    end
  end
end