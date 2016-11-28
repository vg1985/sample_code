Rails.application.routes.draw do
  resources :roles do
    collection do
      get :check_name
    end
  end

  devise_scope :user do
    get '/users/masquerade/back', to: 'devise/masquerades#back'
    get '/users/masquerade/:id', to: 'masquerades#show'
  end

  devise_for :users, controllers: {sessions: 'sessions', passwords: 'passwords' }

  root 'pages#index'
  
  controller 'settings' do 
    match 'settings/bandwidth', action: 'bandwidth', via: :get
    match 'settings/update_bandwidth_settings', action: 'update_bandwidth_settings', via: :patch
    match 'settings/invoices', action: 'invoices', via: :get
    match 'settings/update_invoice_settings', action: 'update_invoice_settings', via: :patch
    match 'settings/zendesk', action: 'zendesk', via: :get
    match 'settings/update_zendesk_settings', action: 'update_zendesk_settings', via: :patch
    match 'settings/payment_gateways', action: 'payment_gateways', via: :get
    match 'settings/update_payment_settings', action: 'update_payment_settings', via: :patch
    match 'settings/mailer', action: 'mailer', via: :get
    match 'settings/update_mailer_settings', action: 'update_mailer_settings', via: :patch
    match 'settings/update_finance_settings', action: 'update_finance_settings', via: :patch
    match 'settings/download_auth_sample', action: 'download_auth_sample', via: :get
    match 'settings/sms', action: 'sms', via: :get
    match 'settings/update_sms_settings', action: 'update_sms_settings', via: :patch
    match 'settings/update_outbound_sms_settings', action: 'update_outbound_sms_settings', via: :patch
    match 'settings/update_sms_other_settings', action: 'update_sms_other_settings', via: :patch
    match 'settings/update_general_settings', action: 'update_general_settings', via: :patch
    match 'settings/general', action: 'general', via: :get
    match 'settings/export_non_existing', action: 'export_non_existing', via: :get
    match 'settings/export_to_zendesk', action: 'export_to_zendesk', via: :get
    match 'settings/refresh_zendesk_assignees', action: 'refresh_zendesk_assignees', via: :get
    match 'settings/otp', action: 'otp', via: :get
    match 'settings/update_otp_settings', action: 'update_otp_settings', via: :patch
  end

  controller 'otps' do
    match 'otps/auth_dialog', action: 'auth_dialog', via: :post
    match 'otps/primary_auth_dialog', action: 'primary_auth_dialog', via: :post
    match 'otps/uemobile_auth_dialog', action: 'uemobile_auth_dialog', via: :post
    match 'otps/generate', action: 'generate', via: :get
  end

  controller 'carrier_settings' do
    match 'carrier/settings/credit_cards', action: 'credit_cards', via: :get
    match 'carrier/settings/update_credit_card_settings', action: 'update_credit_card_settings', via: :patch
  end

  controller 'reports' do
    match 'reports/profit', action: 'profit', via: :get
    match 'reports/get_profit', action: 'get_profit', via: :post
    match 'reports/summary', action: 'summary', via: :get
    match 'reports/get_summary', action: 'get_summary', via: :post
    match 'reports/did', action: 'did', via: :get
    match 'reports/get_did', action: 'get_did', via: :post
    match 'reports/sms', action: 'sms', via: :get
    match 'reports/get_sms', action: 'get_sms', via: :post
    match 'reports/cdr_search', action: 'cdr_search', via: :get
    match 'reports/get_cdr_search', action: 'get_cdr_search', via: :post
    match 'reports/paginated_cdr_search', action: 'paginated_cdr_search', via: :post
    match 'reports/cdr_templates', action: 'cdr_templates', via: :get
    match 'reports/remove_cdr_template/:id', action: 'remove_cdr_template', via: :delete
    match 'reports/save_cdr_template', action: 'save_cdr_template', via: :post
    match 'reports/check_template_name', action: 'check_template_name', via: :get
    match 'reports/ingress_pin_down', action: 'ingress_pin_down', via: :get
    match 'reports/egress_pin_down', action: 'egress_pin_down', via: :get
    match 'reports/cdr_logs', action: 'cdr_logs', via: :get
    match 'reports/get_cdr_logs', action: 'get_cdr_logs', via: :post
    match 'reports/paginated_cdr_logs', action: 'paginated_cdr_logs', via: :post
    match 'reports/username_search', action: 'username_search', via: :get
    match 'reports/did_search', action: 'did_search', via: :get
    match 'reports/get_did_search', action: 'get_did_search', via: :post
    match 'reports/paginated_did_search', action: 'paginated_did_search', via: :post
  end

  controller 'api/v1/smses' do
    match 'sendsms', action: 'sendon', via: :get
  end
  
  resources :admins
  resources :invoices
    
  resources :users do
    collection do
      get :search
      get :check_username
      get :check_email
      post :dt_users_interplay
      post :update_bulk_status
    end

    member do
      get :edit_internal
      patch :update_internal
    end
  end

  resources :sms_logs, only: [:index, :show] do
    collection do
      post :dt_message_logs_interplay
    end
  end

  resources :support, controller: 'support'  do
    collection do
      post :dt_tickets_interplay
      post :attach_file
      get :detach_file
      post :merge
    end
    member do
      get :comments
      get :status
      post :make_comment
    end
  end
  
  resources :rates do
    collection do
      get :check_code
      post :bulk_destroy
    end
  end

  resources :orders, only: [:index, :show] do
    collection do
      post :order_now, action: 'execute_order'
      post :purchase_confirmation
      get :cancel_purchase
      post :dt_orders_interplay
    end
  end
  
  resources :inbound_dids_groups do 
    collection do 
      put :update_did_desc
      put :update_didgrp_desc
      post :create_group
      get :check_group_name
      post :move_to
      post :release
      post :remove_dids
    end
  end

  resources :inbound_dids, only:[] do
    collection do
      get :rates
      get :purchase
      get :manage
      get :search_local_numbers
      get :search_tf_numbers
      get :bulk_voice_settings
      get :bulk_sms_settings
      get :cities
      patch :update_bulk_voice_settings
      patch :update_bulk_sms_settings
    end
    
    member do 
      patch :update_local_rates
      patch :update_tf_rates
      patch :update_did_sms_rates
      get :voice_settings
      get :sms_settings
      patch :update_voice_settings
      patch :update_sms_settings
    end
  end
  
  get 'smses/carrier_sms_dids/:id' => 'smses#carrier_sms_dids'

  resources :smses do
    collection do
      get :send_sms_credit
      #get :carrier_sms_numbers
      get :apis
      get :manage
      get :did_groups
    end
  end

  [:ingress_trunks, :egress_trunks].each do |controller_name|
    resources controller_name do
      member do
        put :activate
        put :deactivate
      end
      collection do
        post :update_bulk_status
        post :bulk_destroy
        get :check_name
        get :check_username
        get :default_username
        post :validate_hosts
        post :dt_trunks_interplay
      end
    end
  end

  get 'carriers/check_company' => 'carriers#check_company'
  get 'carriers/check_email' => 'carriers#check_email'
  get 'carriers/check_mobile' => 'carriers#check_mobile'
  get 'carriers/check_username' => 'carriers#check_username'
  get 'carriers/check_account_code' => 'carriers#check_account_code'
  post 'carriers/unreg_verify_otp' => 'carriers#unreg_verify_otp'
  post 'carriers/check_unique_contacts' => 'carriers#check_unique_contacts'

  resources :carriers do
    member do
      put :enable
      put :disable
      get :egress_trunks
      get :billing_rates
      get :refresh_token
      get :edit_profile
      patch :update_profile
      get :edit_password
      get :contact_options
    end
    collection do
      post :update_bulk_status
      post :dt_carriers_interplay
      get :register
      post :do_register
    end
  end

  resources :rate_sheets do
    resources :user_actions do
      member do
        get :download_details
      end

      collection do
        post :dt_user_actions_interplay
      end
    end
    
    member do
      delete :empty
    end

    collection do
      get :template
      get :check_name
      post :dt_ratesheets_interplay
    end

    member do
      get :export
      post :import
      post :mass_update
      post :search
      get :logs
    end
  end

  get 'payments/carrier_payment_options/:id' => 'payments#carrier_payment_options'
  resources :payments do
    member do
      put :accept
      put :set_delete
      get :paid_by_paypal
      get :express_checkout
      get :finalize
      put :confirm
      get :revoke
    end

    collection do
      get :carrier_payment_options
      post :dt_payments_interplay
      post :dt_charges_interplay
      get :add_charge
      get :charges
    end
  end

  resources :payment_gateways, only: [] do
    collection do
      get :settings
      post :save_settings
    end
  end

  resources :routings do
    member do
      delete :remove_trunk
      patch :trunk_move_up
      patch :trunk_move_down
      patch :activate_trunk
      patch :deactivate_trunk
    end

    collection do 
      get :check_name
      get :search
    end
  end

  resources :credit_cards, only: [:index, :new, :create, :destroy] do
     member do
      resources :documents, controller: "credit_cards" do
        get :download_authorization
        delete :remove_attached_authorization
      end

      get :finalize
      get :confirm
      put :enable
      put :disable
      put :activate
      put :deactivate
      get :check_authorization
      post :attach_authorization
    end

    collection do 
      post :upload_authorization
      get :remove_authorization
      get :check_nickname
      post :dt_cc_interplay
    end
  end

  resources :backend do
    collection do 
      post :paypal_ipn
      post :receive_sms
      post :plivo_status
      get :plivo_status
      post :twilio_status
    end
  end

  resources :inbound_smses

  namespace :api do  
    namespace :v1 do
      resources :smses, except: [:show, :edit, :update] do
        collection do
          get :test
          get :sendon
        end
      end
    end
  end
end
