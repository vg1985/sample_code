class IngressTrunksController < ApplicationController
  after_action :verify_authorized

  before_filter :load_ingress_trunk, except: [:index, :update_bulk_status, :new, :bulk_destroy,
                                              :create, :check_name, :check_username, :validate_hosts,
                                              :default_username, :dt_trunks_interplay]

  def index
    authorize IngressTrunk.new
    
  end

  def dt_trunks_interplay
    authorize IngressTrunk.new, :index?
    
    filter_query = {}

    if policy(:ingress_trunk).select_carrier?
      allowed_carriers = current_user.allowed_carriers

      if allowed_carriers.include?('-10')
        filter_query[:carrier_id] = params[:columns]['2']['search']['value'] if params[:columns]['2']['search']['value'].present?
      else 
        if params[:columns]['2']['search']['value'].present? && allowed_carriers.include?(params[:columns]['2']['search']['value'])
          filter_query[:carrier_id] = params[:columns]['2']['search']['value']
        else
          filter_query = ['carrier_id IN (?)', allowed_carriers]
        end
      end
      
    end
    
    select_clause = 'ingress_trunks.id, ingress_trunks.name, ingress_trunks.is_active, rate_sheets.name AS rate_sheet_name, routings.name AS routing_name'

    search_filter = ['ingress_trunks.name LIKE ? OR 
                      rate_sheets.name LIKE ? OR routings.name LIKE ?', 
                      "%#{params['search']['value']}%", "%#{params['search']['value']}%", "%#{params['search']['value']}%"]

    if policy(:ingress_trunk).select_carrier?
      select_clause += ', carriers.company_name'

      order_by = "#{IngressTrunk::DT_ADMIN_COLS[params[:order]['0'][:column].to_i - 1]} #{params[:order]['0'][:dir]}"
      
      @ingress_trunks = IngressTrunk.where(filter_query).joins([:carrier, :rate_sheet, :routing]).select(select_clause).order(order_by)

      if params['search']['value'].present?
        search_filter[0] = search_filter[0] + ' OR carriers.company_name LIKE ?'
        search_filter[4] = "%#{params['search']['value']}%"
        @ingress_trunks = @ingress_trunks.where(search_filter)
      end

      @ingress_trunks = @ingress_trunks.page(params[:page]).per(params[:length])
        
      @data = @ingress_trunks.collect do |it|
        [it.id, ERB::Util.html_escape(it.name), ERB::Util.html_escape(it.company_name), 
          ERB::Util.html_escape(it.routing_name), ERB::Util.html_escape(it.rate_sheet_name), 
          it.is_active?, 
          [policy(:ingress_trunk).list_deactivate?, policy(:ingress_trunk).list_activate?, 
          policy(:ingress_trunk).list_edit?, policy(:ingress_trunk).list_delete?,
          it.is_active?]]
      end

    else
      @ingress_trunks = []

      if current_user.is_carrier?
        order_by = "#{IngressTrunk::DT_COLS[params[:order]['0'][:column].to_i - 1]} #{params[:order]['0'][:dir]}"
        
        @ingress_trunks = current_user.carrier.ingress_trunks.where(filter_query).joins([:rate_sheet, :routing]).select(select_clause).order(order_by)
        
        if params['search']['value'].present?
          @ingress_trunks = @ingress_trunks.where(search_filter)
        end
        
        @ingress_trunks = @ingress_trunks.page(params[:page]).per(params[:length])
      end
      @data = @ingress_trunks.collect do |it|
        [it.id, ERB::Util.html_escape(it.name), ERB::Util.html_escape(it.routing_name), ERB::Util.html_escape(it.rate_sheet_name), it.is_active?, 
          [policy(:ingress_trunk).list_deactivate?, policy(:ingress_trunk).list_activate?, 
          policy(:ingress_trunk).list_edit?, it.is_active?]]
      end
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    authorize IngressTrunk.new

    @ingress_trunk = IngressTrunk.new
  end

  def create
    @ingress_trunk = IngressTrunk.new(ingress_trunk_params)

    authorize @ingress_trunk

    if @ingress_trunk.save
      flash[:notice] = 'Ingress Trunk has been successfully created.'
    else
      flash[:error] = 'ERROR: Some error occurred while creating the Ingress Trunk. Please contact system administrator.'
      logger.error 'error....' + @ingress_trunk.errors.inspect
    end
    
    redirect_to ingress_trunks_path
  end

  def edit
    authorize @ingress_trunk

    render action: :new
  end
  
  def update
    authorize @ingress_trunk
    
    if policy(:ingress_trunk).select_carrier?
      @ingress_trunk.update_attributes(ingress_trunk_params)

      if @ingress_trunk.errors.any?
        flash[:error] = 'ERROR: Some error occurred while modifying the Ingress Trunk. Please contact system administrator.'
      else
        flash[:notice] = 'Ingress Trunk has been successfully modified.'
      end
    else
      @ingress_trunk.attributes = ingress_trunk_carrier_params
      
      if params[:otpid].present? && params[:otpcode].present?
        if Otp.verify(current_user.id, params[:otpid], params[:otpcode], 'trunk_update')
          if @ingress_trunk.save
            flash[:notice] = 'Ingress Trunk has been successfully modified.'
          else
            flash[:error] = 'ERROR: Some error occurred while modifying the Ingress Trunk. Please contact system administrator.'
            logger.info 'error....' + @ingress_trunk.errors.inspect
          end
        else
          flash[:error] = 'Cannot perform update operation. The OTP is invalid or has expired.'
        end
      else
        if @ingress_trunk.update_otp_auth_required?
          flash[:error] = 'The action could not be performed. This action requires OTP authorization.'
        else 
          if @ingress_trunk.save
            flash[:notice] = 'Ingress Trunk has been successfully modified.'
          else
            flash[:error] = 'ERROR: Some error occurred while modifying the Ingress Trunk. Please contact system administrator.'
            logger.error 'error....' + @ingress_trunk.errors.inspect
          end
        end  
      end
    end

    redirect_to ingress_trunks_path
  end
  
  def activate
    authorize @ingress_trunk

    if policy(:ingress_trunk).select_carrier?
      @ingress_trunk.update_attribute(:is_active, true)
      @success_msg = 'Ingress trunk status updated successfully'
    else
      if params[:otpid].present? && params[:otpcode].present?
        if Otp.verify(current_user.id, params[:otpid], params[:otpcode], 'trunk_act_deact')
          @ingress_trunk.update_attribute(:is_active, true)
          @success_msg = 'Ingress trunk status updated successfully'
        else
          @error_msg = 'Cannot perform update operation. The OTP is invalid or has expired.'
        end
      else
        @error_msg = 'The action could not be performed. This action requires OTP authorization.'
      end
    end

    render :update_status
  end
  
  def deactivate
    authorize @ingress_trunk

    if policy(:ingress_trunk).select_carrier?
      @ingress_trunk.update_attribute(:is_active, false)
      @success_msg = 'Ingress trunk status updated successfully'
    else
      if params[:otpid].present? && params[:otpcode].present?
        if Otp.verify(current_user.id, params[:otpid], params[:otpcode], 'trunk_act_deact')
          @ingress_trunk.update_attribute(:is_active, false)
          @success_msg = 'Ingress trunk status updated successfully'
        else
          @error_msg = 'Cannot perform update operation. The OTP is invalid or has expired.'
        end
      else
        @error_msg = 'The action could not be performed. This action requires OTP authorization.'
      end
    end
    
    render :update_status
  end

  def update_bulk_status
    authorize IngressTrunk.new

    if policy(:ingress_trunk).select_carrier?
      if current_user.allowed_carriers.include?('-10')
        @ingress_trunks = IngressTrunk.where(id: params[:ingress_trunk_ids])
      else
        @ingress_trunks = IngressTrunk.where(
          ['carrier_id IN (?) AND id IN (?)', current_user.allowed_carriers, params[:ingress_trunk_ids]]
        )
      end
      
      if params[:enable].present? && policy(:ingress_trunk).list_activate?
        @ingress_trunks.update_all(is_active: true)
        @success_msg = 'Ingress trunks status updated successfully.'
      elsif params[:enable].blank? && policy(:ingress_trunk).list_deactivate?
        @ingress_trunks.update_all(is_active: false)
        @success_msg = 'Ingress trunks status updated successfully.'
      else
        @error_msg = 'You are not authorized to perform this action.'
      end
      
    else
      if params[:otpid].present? && params[:otpcode].present?
        if Otp.verify(current_user.id, params[:otpid], params[:otpcode], 'trunk_bulk_actdeact')
          @ingress_trunks = current_user.carrier.ingress_trunks.where(id: params[:ingress_trunk_ids])

          if params[:enable].present? && policy(:ingress_trunk).list_activate?
            @ingress_trunks.update_all(is_active: true)
            @success_msg = 'Ingress trunks status updated successfully.'
          elsif params[:enable].blank? && policy(:ingress_trunk).list_deactivate?
            @ingress_trunks.update_all(is_active: false)
            @success_msg = 'Ingress trunks status updated successfully.'
          else
            @error_msg = 'You are not authorized to perform this action.'
          end
        else
          @error_msg = 'Cannot perform update operation. The OTP is invalid or has expired.'
        end
      else
        @error_msg = 'The action could not be performed. This action requires OTP authorization.'
      end
    end

    render :update_status
  end

  def bulk_destroy
    authorize IngressTrunk.new

    if policy(:ingress_trunk).select_carrier?
      if current_user.allowed_carriers.include?('-10')
        @ingress_trunks = IngressTrunk.where(id: params[:ingress_trunk_ids])
      else
        @ingress_trunks = IngressTrunk.where(
          ['carrier_id IN (?) AND id IN (?)', current_user.allowed_carriers, params[:ingress_trunk_ids]]
        )
      end
    else
      @ingress_trunks  = current_user.ingress_trunks.carrier.where(id: params[:ingress_trunk_ids])
    end

    @ingress_trunks.destroy_all
    @success_msg = 'Ingress trunks deleted successfully.'
    
    render :update_status
  end

  def destroy
    authorize @ingress_trunk

    @ingress_trunk.destroy
  end

  def default_username
    skip_authorization
    username = ''
    
    if params[:carrier_id].present?
      carrier = Carrier.find(params[:carrier_id])
      ingress_trunk = IngressTrunk.where(reg_user: carrier.account_code).limit(1)
      if ingress_trunk.blank?
        username = carrier.account_code
      end
    end

    respond_to do |format|
      format.html { render text: username }
    end
  end

  def check_username
    skip_authorization

    @ingress_trunk = IngressTrunk

    if params[:id].to_i > 0
      @ingress_trunk = @ingress_trunk.where(["id != ?", params[:id]])
    end

    @ingress_trunk = @ingress_trunk.where(reg_user: params[:ingress_trunk][:reg_user]).limit(1)
    
    respond_to do |format|
      format.json { render :json => @ingress_trunk.blank? }
    end
  end

  def check_name
    skip_authorization

    @ingress_trunk = IngressTrunk

    if params[:id].to_i > 0
      @ingress_trunk = @ingress_trunk.where(["id != ?", params[:id]])    
    end

    @ingress_trunk = @ingress_trunk.where(name: params[:ingress_trunk][:name]).limit(1)
    
    respond_to do |format|
      format.json { render :json => @ingress_trunk.blank? }
    end
  end

  def validate_hosts
    skip_authorization

    data = params[:data]
    error_rows = []

    if params[:id].to_i > 0
      host_ids = Host.where(["trunk_id = ? AND trunk_type = 'IngressTrunk'", params[:id]]).all.collect(&:id)
    end

    data.each do |row, values|
      if Host.where(['host_ip = ? AND subnet = ? AND port = ? AND id NOT IN (?) AND trunk_type = \'IngressTrunk\'', values[0], values[1], values[2], host_ids.blank? ? -1 : host_ids]).present?
        error_rows << (row.to_i + 1)
      end
    end

    respond_to do |format|
      format.json { render json: error_rows }
    end
  end

  private
  def ingress_trunk_params
    allowed_params = [:id, :carrier_id, :rate_sheet_id, :routing_id, :name, :is_active, :pc_profit_margin, :profit_margin,
                                  :tech_prefix, :media_bypass, :max_duration, :call_limit, :cps_limit, :pdd_timeout, :ring_timeout,
                                  :lrn_source, :lrn_block, :force_cid, :force_rpid, :decimal_points, :sip_trace, :block_wireless,
                                  :profit_margin_type, :try_timeout, :max_cost, :ingress_type]
    
    if params[:ingress_trunk][:ingress_type] == '1'
      allowed_params << {hosts_attributes: hosts_attributes}
    else
      allowed_params << :reg_user
      allowed_params << :reg_password
    end

    params[:ingress_trunk].permit(allowed_params)
  end

  def ingress_trunk_carrier_params
    allowed_params = [:id, :media_bypass, :block_wireless, :force_cid, :ingress_type]
    
    if params[:ingress_trunk][:ingress_type] == '1'
      allowed_params << {hosts_attributes: hosts_attributes}
    else
      allowed_params << :reg_user
      allowed_params << :reg_password
    end

    params[:ingress_trunk].permit(allowed_params)
  end

  def hosts_attributes
    [:id, :host_ip, :subnet, :port, :trunk_id, :trunk_type, :_destroy]
  end

  def load_ingress_trunk
    @ingress_trunk = IngressTrunk.find_by_id(params[:id])
    unless @ingress_trunk
      flash[:error] = "Ingress Trunk not found"
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end

end
