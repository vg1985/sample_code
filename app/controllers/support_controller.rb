class  SupportController < ApplicationController
  after_action :verify_authorized

  def index
    authorize :support, :index?
    #client = Zendesk.config_client
    #client.ticket_fields.all {|r| logger.info r.inspect}
    #req = RestClient::Resource.new 'https://sipsurgesupport1446550083.zendesk.com/api/v2/users/1599925012/identities.json', 'developer.vineet@gmail.com/token', 'kue7gbil7884C4VRXkU9SoyugZISpHL9Ur8pCWbc'
    #client = Zendesk.rest_client('users/1599925012/identities')
    #data = client.get(accept: 'json')
    #resp = RestClient.get '', {:accept => :json}
    #data = ZendeskAPI::User.new(client, id: 1599925012).identities.to_a
    #data = ZendeskAPI::User.new(client, id: 1599925012).identities.create(type: 'email', value: 'apitest@zendesk.com')
    #data = ZendeskAPI::User.new(client, id: 1599925012).identities.find(id: 1009227992)
    #data = client.tickets(path: 'users/1619249572/tickets/requested').to_a.size
    #data = client.tickets.find(id: 6).comments.to_a
    #data = client.tickets.per_page(1)
    #<ZendeskAPI::User {"id"=>1572515922, "url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/users/1572515922.json", "name"=>"Vineet Sethi", "email"=>"developer.vineet@gmail.com", "created_at"=>2015-11-03 11:28:10 UTC, "updated_at"=>2015-11-14 12:53:57 UTC, "time_zone"=>"Eastern Time (US & Canada)", "phone"=>nil, "photo"=>{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/attachments/103716812.json", "id"=>103716812, "file_name"=>"images__8_.jpg", "content_url"=>"https://sipsurgesupport1446550083.zendesk.com/system/photos/0001/0371/6812/images__8_.jpg", "mapped_content_url"=>"https://sipsurgesupport1446550083.zendesk.com/system/photos/0001/0371/6812/images__8_.jpg", "content_type"=>"image/jpeg", "size"=>1235, "inline"=>false, "thumbnails"=>[{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/attachments/103716832.json", "id"=>103716832, "file_name"=>"images__8__thumb.jpg", "content_url"=>"https://sipsurgesupport1446550083.zendesk.com/system/photos/0001/0371/6812/images__8__thumb.jpg", "mapped_content_url"=>"https://sipsurgesupport1446550083.zendesk.com/system/photos/0001/0371/6812/images__8__thumb.jpg", "content_type"=>"image/jpeg", "size"=>1230, "inline"=>false}]}, "locale_id"=>1, "locale"=>"en-US", "organization_id"=>373069782, "role"=>"admin", "verified"=>true, "external_id"=>nil, "tags"=>[], "alias"=>nil, "active"=>true, "shared"=>false, "shared_agent"=>false, "last_login_at"=>2015-11-14 12:37:43 UTC, "two_factor_auth_enabled"=>nil, "signature"=>nil, "details"=>nil, "notes"=>nil, "custom_role_id"=>nil, "moderator"=>true, "ticket_restriction"=>nil, "only_private_comments"=>false, "restricted_agent"=>false, "suspended"=>false, "chat_only"=>false, "user_fields"=>{}, "role_id"=>"admin"}>
    #data = client.users.identities(path: 'users/1599925012/identities').first
    #data = ZendeskAPI::Collection.new(client, ZendeskAPI::User::Identity, user_id: '1599925012', :verb => :get).to_a
    #client.search(:query => "type:ticket status<solved organization:'Zendesk03e Corporation'").count
    #logger.info 'count....' + data.count.inspect
    #logger.info 'data....' + data.to_a.inspect
  
    client = Zendesk.config_client
    # 0.upto(5) do |i|
    #   priority = %w(urgent high normal low)
    #   ZendeskAPI::Ticket.create(client, :subject => "Test Ticket-0#{i}", :comment => { :value => "This is a test#{i}" }, :requester => {"email": "vineet-maze@name03.com"}, :priority => priority[i-1])
    # end
    #ZendeskAPI::Ticket.create(client, :subject => "Test Ticket-low", :comment => { :value => "This ticket is on hold" }, :requester => {"email": "vineet-maze@name03.com"}, :priority => "low", :status => "new")
    respond_to do |format|
      format.html
    end
  end

  def dt_tickets_interplay
    authorize :support, :index?

    client = Zendesk.config_client

    if policy(:support).select_carrier?
      filter_query = 'type:ticket '
      
      if params[:columns]['0']['search']['value'].present?
        allowed_carriers = current_user.allowed_carriers

        if allowed_carriers.include?('-10') || 
          allowed_carriers.include?(params[:columns]['0']['search']['value'])
          carrier = Carrier.find(params[:columns]['0']['search']['value'])
          filter_query += "organization:'#{carrier.company_name}' "
        end
      end
    else
      filter_query = "type:ticket organization:'#{current_user.carrier.company_name}' "
    end

    if params[:columns]['4']['search']['value'].present?
      priority = params[:columns]['4']['search']['value']
      filter_query += "priority:#{priority} "
    end

    if params[:columns]['5']['search']['value'].present?
      status = params[:columns]['5']['search']['value']
      unless '-1' == status
        filter_query += "status:#{status} "
      end
      
    else 
      filter_query += 'status<solved '
    end

    if params['search']['value'].present?
      filter_query += "\"#{params['search']['value']}\" "
    end

    tickets = client.search(
        query: filter_query,
        sort_by: Zendesk::DT_ADMIN_COLS[params[:order]['0'][:column].to_sym], 
        sort_order: params[:order]['0'][:dir]
      ).
      page(params[:page]).
      per_page(params[:length])

    @count = tickets.count
    #{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/tickets/25.json", "id"=>25, "external_id"=>nil, "via"=>{"channel"=>"api", "source"=>{"from"=>{}, "to"=>{}, "rel"=>nil}}, "created_at"=>2015-11-17 07:55:30 UTC, "updated_at"=>2015-11-17 08:00:15 UTC, "type"=>nil, "subject"=>"Test Ticket-00", "raw_subject"=>"Test Ticket-00", "description"=>"This is a test0", "priority"=>"low", "status"=>"open", "recipient"=>nil, "requester_id"=>1621485261, "submitter_id"=>1621485261, "assignee_id"=>nil, "organization_id"=>576157342, "group_id"=>25063662, "collaborator_ids"=>[], "forum_topic_id"=>nil, "problem_id"=>nil, "has_incidents"=>false, "due_at"=>nil, "tags"=>[], "custom_fields"=>[{"id"=>28382602, "value"=>nil}], "satisfaction_rating"=>nil, "sharing_agreement_ids"=>[], "comment_count"=>1, "fields"=>[{"id"=>28382602, "value"=>nil}], "brand_id"=>622242, "result_type"=>"ticket"}
    if @count.present?
       if policy(:support).select_carrier?
        @data = tickets.to_a.collect do |ticket|
          [
            ticket.id,
            ticket.id,
            Carrier.find_by(zendesk_id: ticket.organization_id).try(:company_name), 
            ERB::Util.html_escape(ticket.type),
            ticket.subject,
            ticket.priority,
            ticket.status,
            ticket.created_at.in_time_zone(current_user.timezone).to_s(:carrier),
            ticket.updated_at.in_time_zone(current_user.timezone).to_s(:carrier),
            [ticket.id, ticket.tags.collect(&:id).join(', '),
              policy(:support).destroy?,
              policy(:support).close_ticket?,
              policy(:support).add_tags?]
          ]
        end
      else
        @data = tickets.to_a.collect do |ticket|
          [
            ticket.id,
            ERB::Util.html_escape(ticket.type.try(:titlecase)),
            ticket.subject,
            ticket.priority,
            ticket.status,
            ticket.created_at.in_time_zone(current_user.carrier.timezone).to_s(:carrier),
            ticket.updated_at.in_time_zone(current_user.carrier.timezone).to_s(:carrier),
            [ticket.id, ticket.tags.collect(&:id).join(', '),
              policy(:support).destroy?,
              policy(:support).close_ticket?,
              policy(:support).add_tags?]
          ]
        end
      end
    else
      @count = []
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    authorize :support, :create_ticket?

    if policy(:support).select_carrier?
      allowed_carriers = current_user.allowed_carriers

      if allowed_carriers.include?('-10')
        @carriers = Carrier.for_support
      else
        @carriers = Carrier.for_support(allowed_carriers)
      end
    end
  end

  def create
    authorize :support, :create_ticket?

    if policy(:support).select_carrier?
      org_id = params[:ticket][:carrier_id]
    else
      org_id = carrier.zendesk_id
    end

    unless has_permissions(org_id, true)
      flash[:error] = 'You do not have permissions to create ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return  }
      end
    end

    ticket = Zendesk.create_ticket(ticket_params)

    if ticket.id.present?
      flash[:notice] = 'Support ticket has been created successfully.'
    else
      flash[:error] = 'Support ticket could not be generated. Please contact administrator.'
    end

    redirect_to support_index_path
  end

  def edit
    authorize :support, :update_ticket?

    unless has_permissions(params[:id])
      flash[:error] = 'You do not have permissions to update this ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return }
      end
    end

    if policy(:support).select_carrier?
      allowed_carriers = current_user.allowed_carriers

      if allowed_carriers.include?('-10')
        @carriers = Carrier.for_support
      else
        @carriers = Carrier.for_support(allowed_carriers)
      end
      
      @email_options = []

      if @ticket.organization_id.present?
        carrier = Carrier.find_by_zendesk_id(@ticket.organization_id)
        @email_options = carrier.emails_for_support
      end
    else
      @email_options = current_user.carrier.emails_for_support
    end

    @collaborators = Zendesk.get_users_info(@ticket.collaborator_ids)

    @cc_to = @email_options.dup
    contacts = @email_options.flatten

    @collaborators.each do |id, user|
      unless contacts.include?(id)
        @cc_to << ["#{user[0]} #{user[1]}", id]
      end
    end
    
    respond_to do |format|
      format.html
    end
  end

  def update
    authorize :support, :update_ticket?

    unless has_permissions(params[:id])
      flash[:error] = 'You do not have permissions to update this ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return }
      end
    end

    submitted = Zendesk.update_ticket(@ticket, update_ticket_params)

    if submitted
      flash[:notice] = 'Support ticket has been updated successfully.'
    else
      flash[:error] = 'Support ticket could not be updated. Please contact administrator.'
    end

    redirect_to support_index_path
  end

  def show
    authorize :support, :show?

    unless has_permissions(params[:id])
      flash[:error] = 'You do not have permissions to view this ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return }
      end
    end

    users = [@ticket.requester_id, @ticket.submitter_id, @ticket.assignee_id]
    
    if @ticket.collaborator_ids.present?
      users = users + @ticket.collaborator_ids
    end

    @users = Zendesk.get_users_info(users.compact.uniq)

    if @ticket.group_id.present?
      @group = Zendesk.get_group_info(@ticket.group_id)
    end
    
    if @ticket.blank?
      flash[:error] = 'Error! This ticket could not be found in the system.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return }
      end
    end
=begin
    if @ticket.status == 'solved' || @ticket.status == 'closed'
      respond_to do |format|
        format.html { redirect_to support_index_path and return }
      end
    end
=end
    if policy(:support).select_carrier?
      @timezone = current_user.timezone.present? ? current_user.timezone : Time.zone.name
    else
      @timezone = current_user.carrier.timezone
    end
                                                                
    respond_to do |format|
      format.html
    end
  end

  def comments
    authorize :support, :comments?
    unless has_permissions(params[:id])
      flash[:error] = 'You do not have permissions to view this ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return  }
      end
    end

    @comments = Zendesk.get_comments(@ticket.id)
    #logger.info 'comments....' + @comments.inspect
    user_ids = [current_user.zendesk_id]

    if @comments.present?
      user_ids = user_ids + @comments.collect { |c| c.author_id }
    end

    @users = Zendesk.get_users_info(user_ids)

    if policy(:support).select_carrier?
      @timezone = current_user.timezone.present? ? current_user.timezone : Time.zone.name
    else
      @timezone = current_user.carrier.timezone
    end

    respond_to do |format|
      format.html {render layout: false}
    end
  end

  def destroy
    authorize :support, :destroy?
    
    unless has_permissions(params[:id])
      flash[:error] = 'You do not have permissions to view this ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return  }
      end
    end

    done = Zendesk.delete_ticket(@ticket.id)

    if done
      flash[:notice] = 'The ticket has been deleted successfully'
    else
      flash[:error] = 'This ticket could not be deleted.'
    end

    redirect_to support_index_url and return
  end

  def status
    authorize :support, :status?

    valid_statuses = %w(new open pending solved)
    if policy(:support).close_ticket?
      valid_statuses << 'closed'
    end

    if params[:status].blank? || !valid_statuses.include?(params[:status])
      flash[:error] = 'This is an invalid status.'
      redirect_to :back and return
    end

    unless has_permissions(params[:id])
      flash[:error] = 'You do not have permissions to view this ticket.'
      respond_to do |format|
        format.html { redirect_to support_index_path and return  }
      end
    end

    done = Zendesk.ticket_status(@ticket.id, params[:status])

    flash[:notice] = 'Ticket has been successfully updated'
    redirect_to :back and return
  end

  def make_comment
    authorize :support, :make_comment?

    comment_data = nil
    if params[:comment][:body].present?
      comment_data = {author_id: current_user.zendesk_id, body: params[:comment][:body], public: params[:comment][:internal] != '1'}
      if params[:comment][:uploads].present?
        comment_data[:uploads] = params[:comment][:uploads].split(',')
      end
    end

    Zendesk.save_comment(params[:id], comment_data, params[:comment][:status])

    respond_to do |format|
      format.html {redirect_to support_url(params[:id])}
      format.js
    end
  end

  def merge
    authorize :support, :merge?

    resp = Zendesk.merge(params[:source_ticket_ids].split(','), params[:ticket_id],
      params[:source_comment], params[:target_comment])

    if resp
      flash[:notice] = 'Merge has happened successfully. Updates will take effect in few moments.'
    else
      flash[:error] = 'Merge could not happen. Please contact administrator for further info.'
    end

    respond_to do |format|
      format.html { redirect_to support_index_path  }
    end
  end

  def attach_file
    authorize :support, :show?

    if params[:file].present?
      error = false
      result = Zendesk.upload_attachment(params[:file].original_filename, params[:file].path, params[:file].content_type)
      #logger.info 'result...' + result.inspect
      if result['upload'].present? && result['upload']['token'].present?
        resJson = { status: :success, token:  result['upload']['token'] }
      else 
        error = true
      end
      #{"upload"=>{"token"=>"HMnChyqDHRHdwf8eNdwzN8Sm8", "expires_at"=>"2015-11-23T09:12:47Z", "attachments"=>[{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/attachments/1201055381.json", "id"=>1201055381, "file_name"=>"Barber.gif", "content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/fn1aUrqI7sGLKadJUxZYYNi6X/?name=Barber.gif", "mapped_content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/fn1aUrqI7sGLKadJUxZYYNi6X/?name=Barber.gif", "content_type"=>"image/gif", "size"=>8783, "inline"=>false, "thumbnails"=>[{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/attachments/1201055401.json", "id"=>1201055401, "file_name"=>"Barber_thumb.gif", "content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/oF1q0sTOkLdeH15MGoGmbqQaM/?name=Barber_thumb.gif", "mapped_content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/oF1q0sTOkLdeH15MGoGmbqQaM/?name=Barber_thumb.gif", "content_type"=>"image/gif", "size"=>8783, "inline"=>false}]}], "attachment"=>{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/attachments/1201055381.json", "id"=>1201055381, "file_name"=>"Barber.gif", "content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/fn1aUrqI7sGLKadJUxZYYNi6X/?name=Barber.gif", "mapped_content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/fn1aUrqI7sGLKadJUxZYYNi6X/?name=Barber.gif", "content_type"=>"image/gif", "size"=>8783, "inline"=>false, "thumbnails"=>[{"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/attachments/1201055401.json", "id"=>1201055401, "file_name"=>"Barber_thumb.gif", "content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/oF1q0sTOkLdeH15MGoGmbqQaM/?name=Barber_thumb.gif", "mapped_content_url"=>"https://sipsurgesupport1446550083.zendesk.com/attachments/token/oF1q0sTOkLdeH15MGoGmbqQaM/?name=Barber_thumb.gif", "content_type"=>"image/gif", "size"=>8783, "inline"=>false}]}}}
    end

    respond_to do |format|
      format.json {
        if error
          render text: 'Unexpected error occurred.', status: 500
        else
          render json: resJson.to_json 
        end
      }
    end
  end

  def detach_file
    authorize :support, :show?

    if params[:token].present?
      Zendesk.detach_attachment(params[:token])
    end

    render nothing: true
  end

	def sso
		# Configuration
	  #@secret = '6NWKLNaxgnIPj9Rsku4mqJ7AZuke4Y5ZEANlu4G6tWjYsObu'
	  @secret = 'VEAoKVSHg5DTdiI8L5b35DtZMSaf2drr27dmeirPkXFvFA5q'
	  #@subdomain     = 'sipsurgesupport'
	  @subdomain =  'sipsurgesupport1446550083'

	  require 'securerandom' unless defined?(SecureRandom)

	  iat = Time.now.to_i
    jti = "#{iat}/#{SecureRandom.hex(18)}"

    payload = JWT.encode({
      :iat   => iat, # Seconds since epoch, determine when this token is stale
      :jti   => jti, # Unique token id, helps prevent replay attacks
      :name  => 'Vishal Sethi',
      :email => 'vishal@aleeninfosol.com',
    }, @secret)

    redirect_to zendesk_sso_url(payload)
	end

	private
	def zendesk_sso_url(payload)
    url = "https://#{@subdomain}.zendesk.com/access/jwt?jwt=#{payload}"
    url += "&return_to=#{URI.escape(params["return_to"])}" if params["return_to"].present?
    url
  end

  def ticket_params
    post_params = params[:ticket].permit(:carrier_id, :requester_id, :requester_name, :cc_to, :phone, :subject,
                            :type, :priority, :tags, :comment)

    post_params[:submitter_id] = current_user.zendesk_id
    post_params[:comment] = "Name: #{post_params[:requester_name]}
                            Phone: #{post_params[:phone].split(',').to_sentence}
                            Subject: #{post_params[:subject]}
                            Message:
                            #{post_params[:comment]}"
    post_params[:collaborators] = post_params[:cc_to].split(',')
    post_params[:tags] = post_params[:tags].split(',') if post_params[:tags].present?
    
    if Setting.zendesk_default_assignee.present?
      post_params[:group_id] = Setting.zendesk_default_assignee
    end
    post_params
  end

  def update_ticket_params
    post_params = params[:ticket].permit(:carrier_id, :requester_id, :cc_to,
                            :type, :priority, :tags)

    post_params[:submitter_id] = current_user.zendesk_id
    post_params[:collaborators] = post_params[:cc_to].split(',')
    post_params[:tags] = post_params[:tags].split(',') if post_params[:tags].present?
    
    post_params
  end

  def has_permissions(id, is_org = false)
    if is_org
      organization_id = id.to_s
    else
      @ticket = Zendesk.get_ticket(id)
      logger.info 'ticket...' + @ticket.inspect
      #<ZendeskAPI::Ticket {"url"=>"https://sipsurgesupport1446550083.zendesk.com/api/v2/tickets/27.json", "id"=>27, "external_id"=>nil, "via"=>{"channel"=>"api", "source"=>{"from"=>{}, "to"=>{}, "rel"=>nil}}, "created_at"=>2015-11-17 07:55:40 UTC, "updated_at"=>2015-11-17 12:23:18 UTC, "type"=>nil, "subject"=>"Test Ticket-02", "raw_subject"=>"Test Ticket-02", "description"=>"This is a test2", "priority"=>"high", "status"=>"new", "recipient"=>nil, "requester_id"=>1620280301, "submitter_id"=>1621485261, "assignee_id"=>nil, "organization_id"=>554030892, "group_id"=>25063662, "collaborator_ids"=>[], "forum_topic_id"=>nil, "problem_id"=>nil, "has_incidents"=>false, "due_at"=>nil, "tags"=>[], "custom_fields"=>[{"id"=>28382602, "value"=>nil}], "satisfaction_rating"=>nil, "sharing_agreement_ids"=>[], "comment_count"=>2, "fields"=>[{"id"=>28382602, "value"=>nil}], "brand_id"=>622242}>
      
      if @ticket.blank?
        flash[:error] = 'Invalid Ticket ID. Ticket could not be found.'
        respond_to do |format|
          format.html { redirect_to support_index_path and return }
        end
      end

      organization_id = @ticket.organization_id.to_s
    end

    if policy(:support).select_carrier?
      allowed_carriers = current_user.allowed_carriers

      unless allowed_carriers.include?('-10')
        allowed_org_ids = Carrier.where(['id IN (?)', allowed_carriers])
                          .select('zendesk_id')
                          .collect(&:zendesk_id)
        unless allowed_org_ids.include?(organization_id)
          return false
        end
      end
    else
      unless current_user.carrier.zendesk_id == organization_id
        return false
      end
    end

    return true
  end
end
