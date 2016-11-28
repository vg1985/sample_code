class InboundSmsesController < ApplicationController
	skip_before_action :authenticate_user!

	def index
		 #Parameters: {"to"=>"+15102980799", "time"=>"2016-01-04T07:36:53Z", "text"=>"55555", "direction"=>"in", "applicationId"=>"a-zezsjibk3zkp7z2epaa7bmy", "state"=>"received", "from"=>"+16784214747", "eventType"=>"sms", "messageId"=>"m-l2wt3offp3yqrgwv6hekf6i", "messageUri"=>"https://api.catapult.inetwork.com/v1/users/u-5rfnnm54fbtq4p3t7mzhx5i/messages/m-l2wt3offp3yqrgwv6hekf6i"}
		render nothing: true
	end
end
