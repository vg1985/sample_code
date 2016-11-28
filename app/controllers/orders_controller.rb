class OrdersController < ApplicationController
  after_action :verify_authorized

  def index
    authorize Order.new

    if policy(:order).select_carrier? 
      @carriers = Carrier.all
    end
    
    respond_to do |format|
      format.html
    end
  end

  def dt_orders_interplay
    authorize Order.new, :index?
    
    filter_query = {}

    if policy(:order).select_carrier?
      filter_query[:carrier_id] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?
      filter_query[:status] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?
      filter_query[:transaction_type] = params[:columns]['4']['search']['value'] if params[:columns]['4']['search']['value'].present?.present?
    else
      filter_query[:status] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?
      filter_query[:transaction_type] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?.present?
    end

    select_clause = 'orders.id, orders.email, orders.sipsurge_order_id,  orders.transaction_type, 
                    orders.did_transaction_type, orders.dids, orders.status, orders.created_at';

    if policy(:order).select_carrier?
      select_clause += ' ,carriers.company_name, users.name AS user_name'
      order_by = "#{Order::DT_ADMIN_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      
      @orders = Order.where(filter_query).joins([:carrier, :user]).select(select_clause).order(order_by)

      if params[:columns]['6']['search']['value'].present?
        @orders = @orders.where('dids like ?', "%#{params[:columns]['6']['search']['value']}%")
      end

      @orders = @orders.page(params[:page]).per(params[:length])
        
      @data = @orders.collect do |order| 
        { 
          'DT_RowClass': 'clickable-row', 'DT_RowData': {'href': "#{order_path(order.sipsurge_order_id)}"},
          '0': order.company_name, 
          '1': order.sipsurge_order_id, 
          '2': order.created_at.in_time_zone(current_user.timezone).to_s(:carrier),
          '3': Order::STATUS_NAMES[order.status], 
          '4': order.transaction_type.humanize, 
          '5': order.did_transaction_type.humanize, 
          '6': order.dids_count, 
          '7': order.user_name
        }
      end

    else
      order_by = "#{Order::DT_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      
      @orders = current_user.carrier.orders.where(filter_query).select(select_clause).order(order_by)
      
      if params[:columns]['5']['search']['value'].present?
        @orders = @orders.where("dids like ?", "%#{params[:columns]['5']['search']['value']}%")
      end
      
      @orders = @orders.page(params[:page]).per(params[:length])
      
      @data = @orders.collect do |order|
        { 
          'DT_RowClass': 'clickable-row', 'DT_RowData': {'href': "#{order_path(order.sipsurge_order_id)}"},
          '0': order.transaction_type.humanize, '1': order.sipsurge_order_id, '2': order.created_at.in_time_zone(carrier.timezone).to_s(:carrier),
          '3': Order::STATUS_NAMES[order.status], '4': order.did_transaction_type.humanize, '5': order.dids_count, '6': order.email
        }
      end
    end

    respond_to do |format|
      format.json
    end
  end

  def show 
    #{"DisconnectedTelephoneNumberList"=>{"TelephoneNumber"=>["9103561531", "9103561532", "9103561537"]}, "orderRequest"=>{"Name"=>"User#Vineet Sethi-release", "OrderCreateDate"=>"2015-08-08T06:01:20.684Z", "id"=>"54f3a9ea-0d97-46c1-b83e-779969d0c2eb", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["9103561531", "9103561532", "9103561537"]}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"COMPLETE"}
    #{"DisconnectedTelephoneNumberList"=>{"TelephoneNumber"=>["8777366148", "8777366218"]}, "orderRequest"=>{"Name"=>"User#Vineet Sethi-release", "OrderCreateDate"=>"2015-08-08T06:01:25.752Z", "id"=>"d00f4b76-34ec-4014-bd75-d2c7e363be40", "DisconnectTelephoneNumberOrderType"=>{"TelephoneNumberList"=>{"TelephoneNumber"=>["8777366148", "8777366218"]}, "DisconnectMode"=>"normal"}}, "OrderStatus"=>"COMPLETE"}
    @carrier = current_user.carrier
    @order = Order.find_by(sipsurge_order_id: params[:id])    

    authorize @order

    if @order.blank?
      flash[:error] = 'You are not authorized to view this order.'
      redirect_to orders_url and return      
    end

    respond_to do |format|
      format.html {
        if @order.transaction_type == 'Release'
          render action: :released
        else
          render action: :purchased
        end
      }
    end
  end

  def purchase_confirmation
    if params[:ordersfor].blank?
      flash[:error] = 'Error: Order does not contain any numbers.'
      redirect_to purchase_inbound_dids_url and return
    end
    
    unless %w(local toll_free).include?(params[:order_type])
      flash[:error] = 'Error: Invalid order type posted.'
      redirect_to purchase_inbound_dids_url and return        
    end
    
    if params[:time_left_for_order_conf].present?
      time_left_in_mins = params[:time_left_for_order_conf].split(":")
      @time_left_for_confirmation = (time_left_in_mins[0].to_i * 60).to_i + time_left_in_mins[1].to_i 
    else
      @time_left_for_confirmation = 300 #seconds
    end  
    
    @carrier = current_user.is_admin? ? Carrier.find_by(id: params[:carrier]) : current_user.carrier
    
    if @carrier.blank?
      flash[:error] = 'Selected carrier does not exists.'
      redirect_to purchase_inbound_dids_url and return
    end
    
    @did_rate = @carrier.did_rate_by_type(params[:order_type])

    skip_authorization
    
    session['order'] = {'ordersfor' => params[:ordersfor], 'order_type' => params[:order_type], 'carrier' => @carrier.id}
  end

  def execute_order
    @carrier = current_user.is_admin? ? Carrier.find_by(id: session['order']['carrier']) : current_user.carrier

    if @carrier.blank?
      flash[:error] = 'Selected carrier does not exists.'
      redirect_to purchase_inbound_dids_url and return
    end

    skip_authorization

    if session['order'].blank? || session['order']['ordersfor'].blank? ||
        !(%w(local toll_free).include?(session['order']['order_type'])) || params[:order_email].blank?
        
        flash[:error] = 'Error: Could not execute ordering. Invalid order params.'
        redirect_to purchase_inbound_dids_url and return      
    end  

    unless @carrier.purchase_valid?(session['order']['order_type'], session['order']['ordersfor'].size)
      if current_user.is_admin?
        flash[:error] = 'Error: Could not execute ordering. You do not have enough credit to execute this order.'
      else
        flash[:error] = 'Error: Could not execute ordering. Carrier does not have enough credit for this purchase.'
      end
      redirect_to purchase_inbound_dids_url and return
    end

    order = Order.execute(@carrier, current_user.id, session['order']['order_type'], session['order']['ordersfor'], request.remote_ip, params[:order_email])
    
    session['order'] = nil

    if Order::STATUS_PENDING == order.status 
      flash[:notice] = "Order has been placed successfully. Your order number is <a href='#{order_path(order.sipsurge_order_id)}'>#{order.sipsurge_order_id}</a>. Please quote this order number for future reference."
    else
      flash[:error] = "Sorry! Your order <a href='#{order_path(order.sipsurge_order_id)}'>#{order.sipsurge_order_id}</a> could not be processed at this moment. Please try after sometime or contact customer care."
    end

    if current_user.is_admin?
      redirect_to purchase_inbound_dids_url
    else
      redirect_to orders_url
    end
    
  end

  def cancel_purchase
    skip_authorization
    session['order'] = nil
    
    if params[:timeout].present?
      flash[:notice] = 'Oops! Time is out. You can search the numbers again and order.'
    else
      flash[:notice] = 'Your current order has been cancelled. You can search the numbers again and order.'
    end

    
    redirect_to purchase_inbound_dids_url and return
  end
end
