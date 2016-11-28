require 'zendesk_api'

class Zendesk
	DT_ADMIN_COLS = {'1': 'ticket_type', '4': 'priority', '5': 'status', '6': 'created_at', '7': 'updated_at'}
	
	TICKET_TYPES = {
		problem: 'Report a problem',
		incident: 'Report an incident',
		question: 'General Inquiry',
		task: 'Task to do',
	}

	TICKET_PRIORITY = {
		urgent: 'Critical',
		high: 'High',
		normal: 'Normal',
		low: 'Low'
	}

	class << self
		#for temporary use till zendesk ruby client support the required resources
		def rest_client(path) 
			s = Setting.find_by(uid: 'zendesk')

			if 'token' == s.zendesk_auth_method
				u = "#{s.zendesk_username}/token"
				p = s.zendesk_token
			else
				u = s.zendesk_username
				p = s.zendesk_password
			end
			RestClient::Resource.new "#{s.zendesk_url}/api/v2/#{path}", u, p
		end

		def client(url, username, token, password = nil, auth_method = 'token', logger = Logger.new(STDOUT))
			client = ZendeskAPI::Client.new do |config|
			  # e.g. https://mydesk.zendesk.com/api/v2
			  config.url = "#{url}/api/v2"

			  # Basic / Token Authentication
			  config.username = username

			  # Choose one of the following depending on your authentication choice
			  if 'token' == auth_method
			    config.token = token
			  else
			    config.password = password
			  end

			  # OAuth Authentication
			  config.access_token = nil

			  # Optional:

			  # Retry uses middleware to notify the user
			  # when hitting the rate limit, sleep automatically,
			  # then retry the request.
			  config.retry = true

			  # Logger prints to STDERR by default, to e.g. print to stdout:
			  require 'logger'
			  config.logger = logger
			end
		end

		def config_client
			s = Setting.find_by(uid: 'zendesk')
			client(s.zendesk_url, s.zendesk_username, s.zendesk_token, s.zendesk_password, s.zendesk_auth_method)
		end

		def get_ticket(id)
			client = config_client
			client.tickets.find(id: id)
		end

		def create_end_user(org_id, name, email)
			client = config_client

			client.users.create(organization_id: org_id, name: name, email: email, verified: true)
		end

		def create_admin(name, email)
			client = config_client

			client.users.create(role: 'admin', name: name, email: email, verified: true)
		end

		def create_agent(name, email)
			client = config_client

			client.users.create(role: 'agent', name: name, email: email, verified: true)
		end

		def update_user(id, name, email, role = nil)
			client = config_client
			
			user = ZendeskAPI::User.update(client, id: id, name: name, role: role)

			if user.email != email
				update_email(id, email)
			end
			#user.save
		end

		def destroy_user(id)
			client = config_client
			ZendeskAPI::User.destroy(client, id: id)
		end

		def create_org(name)
			client = config_client

			client.organization.create(name: name)
		end

		def update_org(id, name)
			client = config_client
			ZendeskAPI::Organization.update(client, id: id, name: name)
		end

		def destroy_org(id) 
			client = config_client
			ZendeskAPI::Organization.destroy(client, id: id)
		end

		def create_identity(id, type, value)
			client = config_client
			ZendeskAPI::User.new(client, id: id).identities.create(type: type, value: value, verfied: true)
		end

		def get_identity(carrier_id, id)
			client = config_client
			ZendeskAPI::User.new(client, id: carrier_id).identities.find(id: id)
		end

		def update_identity(carrier_id, id, email)
			client = config_client
			identity = Zendesk.get_identity(carrier_id, id)
			identity.value = email
			identity.save
		end

		def destroy_identity(carrier_id, id) 
			client = config_client
			ZendeskAPI::User.new(client, id: carrier_id).identities.destroy(id: id)
		end

		def user_identities(id)
			client = config_client
			ZendeskAPI::User.new(client, id: id).identities.to_a
		end

		def user_primary_email_identity(id)
			identities = user_identities(id)
			identities.detect{ |identity| 'email' == identity.type && identity.primary }
		end

		def update_email(id, email)
			email_identity = user_primary_email_identity(id)
			email_identity.value = email
			email_identity.save
		end

		def search_user_by_email(email_id)
			client = Zendesk.config_client
			client.search(query: "type:user email:#{email_id}").to_a.first
		end

		def search_org_by_name(org_name)
			client = Zendesk.config_client
			client.search(query: "type:organization name:'#{org_name}'").to_a.first
		end

		def get_comments(ticket_id)
			client = config_client
			ZendeskAPI::Ticket.new(client, id: ticket_id).comments.fetch
		end

		def save_comment(ticket_id, data, set_status = nil)
			client = config_client
			ticket = ZendeskAPI::Ticket.new(client, id: ticket_id)
			ticket.status = set_status if set_status.present?
			ticket.comment = data if data.present?
			ticket.save
		end

		def get_users(ids)
			client = config_client

			client.users.show_many(verb: :get, ids: ids)
		end

		def get_users_info(ids)
			users_data = Zendesk.get_users(ids).to_a

			users_data.inject({}) do |result, e|
        result[e.id.to_s] = [e.name, e.email, e.photo.present? ? e.photo.content_url : 'https://secure.gravatar.com/avatar/6abad1653a18064022d688afcf8c1dd2?d=https%3A//assets.zendesk.com/images/types/user_sm.png&s=30&r=g']
        result
      end
		end

		def get_group_info(grp_id)
			client = config_client
			client.group.find!(id: grp_id)
		end

		def create_ticket(data)
			client = config_client

			client.tickets.create!(subject: data[:subject], comment: {value: data[:comment]}, submitter_id: data[:submitter_id], 
				requester_id: data[:requester_id], priority: data[:priority], tags: data[:tags], type: data[:type],
				collaborators: data[:collaborators], group_id: data[:group_id])
		end

		def update_ticket(ticket, data)
			client = config_client

			if ticket.group_id.blank? &&
				Setting.zendesk_default_assignee.present?

				ticket.group_id = Setting.zendesk_default_assignee
	    end

	    ticket.submitter_id = data[:submitter_id]
	    ticket.requester_id = data[:requester_id]
	    ticket.priority = data[:priority]
	    ticket.tags = data[:tags] if data[:tags].present?
	    ticket.type = data[:type]
	    ticket.collaborators = data[:collaborators]
			
			ticket.save!
		end

		def delete_ticket(id)
			client = config_client
			ZendeskAPI::Ticket.new(client, id: id).destroy
		end

		def ticket_status(id, status)
			client = config_client
			ticket = ZendeskAPI::Ticket.new(client, id: id)
			ticket.status = status
			ticket.save
		end

		def upload_attachment(filename, filepath, content_type)
			client = Zendesk.rest_client("uploads.json?filename=#{filename}")
			ActiveSupport::JSON.decode(client.post(File.read(filepath), content_type: content_type))
		end

		def detach_attachment(token)
			client = config_client
			ZendeskAPI::Upload.new(client, token: token).destroy
		end

		def get_groups
			client = config_client

			client.groups.to_a
		end

		def merge(ticket_ids, to_ticket_id, 
			closing_comment, merge_comment)
			
			return false if ticket_ids.blank? || to_ticket_id.blank?

			client = config_client
			ZendeskAPI::Ticket.new(client, id: to_ticket_id).
				merge(ids: ticket_ids, 
					target_comment: merge_comment,
					source_comment: closing_comment)
		end
	end
end
