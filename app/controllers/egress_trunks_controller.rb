class EgressTrunksController < ApplicationController
  after_action :verify_authorized

  before_filter :load_egress_trunk, except: [:index, :update_bulk_status, :new, :bulk_destroy,
                                              :create, :check_name, :check_username, :validate_hosts,
                                              :default_username, :dt_trunks_interplay]

  def index
    authorize EgressTrunk.new

    @egress_trunks = EgressTrunk.all
  end

  def dt_trunks_interplay
    authorize EgressTrunk.new, :index?
    
    filter_query = {}

    
    filter_query[:carrier_id] = params[:columns]["2"]["search"]["value"] if params[:columns]["2"]["search"]["value"].present?
    #filter_query[:status] = params[:columns]["3"]["search"]["value"] if params[:columns]["3"]["search"]["value"].present?
    #filter_query[:transaction_type] = params[:columns]["4"]["search"]["value"] if params[:columns]["4"]["search"]["value"].present?.present?

    select_clause = "egress_trunks.id, egress_trunks.name, egress_trunks.is_active, carriers.company_name, 
                     rate_sheets.name AS rate_sheet_name, egress_trunks.pdd_timeout";
    
    order_by = "#{EgressTrunk::DT_ADMIN_COLS[params[:order]["0"][:column].to_i - 1]} #{params[:order]["0"][:dir]}"
    
    @egress_trunks = EgressTrunk.where(filter_query).joins([:carrier, :rate_sheet]).select(select_clause).order(order_by)

    if params["search"]["value"].present?
      @egress_trunks = @egress_trunks.where("egress_trunks.name LIKE ? OR rate_sheets.name LIKE ?", 
                                              "%#{params["search"]["value"]}%", "%#{params["search"]["value"]}%")
    end

    @egress_trunks = @egress_trunks.page(params[:page]).per(params[:length])
      
    @data = @egress_trunks.collect do |it|
      [it.id, ERB::Util.html_escape(it.name), ERB::Util.html_escape(it.company_name), ERB::Util.html_escape(it.rate_sheet_name), it.pdd_timeout, it.is_active?]
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    authorize EgressTrunk.new
    @egress_trunk = EgressTrunk.new
  end

  def create
    @egress_trunk = EgressTrunk.create(egress_trunk_params)

    authorize @egress_trunk

    if @egress_trunk.errors.empty?
      flash[:notice] = "Egress Trunk has been successfully created."
    else
      flash[:error] = "ERROR: Some error occurred while creating the Egress Trunk. Please contact system administrator."
      logger.info 'error....' + @egress_trunk.errors.inspect
    end
    
    redirect_to egress_trunks_path
  end

  def edit
    authorize @egress_trunk

    render action: :new
  end
  
  def update
    authorize @egress_trunk

    @egress_trunk.update_attributes(egress_trunk_params)

    if @egress_trunk.errors.empty?
      flash[:notice] = "Egress Trunk has been successfully modified."
    else
      flash[:error] = "ERROR: Some error occurred while modifying the Egress Trunk. Please contact system administrator."
      logger.info 'error....' + @egress_trunk.errors.inspect
    end

    redirect_to egress_trunks_path
  end
  
  def activate
    authorize @egress_trunk

    @egress_trunk.update_attribute(:is_active, true)

    respond_to do |format|
      format.html {redirect_to :back}
      format.js {render :update_status}
    end
    
  end
  
  def deactivate
    authorize @egress_trunk

    @egress_trunk.update_attribute(:is_active, false)

    respond_to do |format|
      format.html {redirect_to :back}
      format.js {render :update_status}
    end
  end

  def update_bulk_status
    authorize EgressTrunk.new

    @egress_trunks = EgressTrunk.where(id: params[:egress_trunk_ids])
    @egress_trunks.update_all(is_active: params[:enable].present? ? true : false)
    render :update_status
  end

  def bulk_destroy
    authorize EgressTrunk.new

    EgressTrunk.where(id: params[:egress_trunk_ids]).destroy_all
    
    render :update_status
  end

  def destroy
    authorize @egress_trunk

    @egress_trunk.destroy
  end

  def check_name
    skip_authorization

    @egress_trunk = EgressTrunk

    if params[:id].to_i > 0
      @egress_trunk = @egress_trunk.where(["id != ?", params[:id]])    
    end

    @egress_trunk = @egress_trunk.where(name: params[:egress_trunk][:name]).limit(1)
    
    respond_to do |format|
      format.json { render :json => @egress_trunk.blank? }
    end
  end

  def validate_hosts
    skip_authorization

    data = params[:data]
    error_rows = []

    if params[:id].to_i > 0
      host_ids = Host.where(["trunk_id = ? AND trunk_type = 'EgressTrunk'", params[:id]]).all.collect(&:id)
    end

    data.each do |row, values|
      if Host.where(['host_ip = ? AND subnet = ? AND port = ? AND id NOT IN (?) AND trunk_type = \'EgressTrunk\'', values[0], values[1], values[2], host_ids.blank? ? -1 : host_ids]).present?
        error_rows << (row.to_i + 1)
      end
    end

    respond_to do |format|
      format.json { render json: error_rows }
    end
  end

  private
  def egress_trunk_params
    params[:egress_trunk].permit([:id, :carrier_id, :rate_sheet_id, :depth, :name, :pc_profit_margin, :profit_margin, :routing_strategy,
                                  :tech_prefix, :media_bypass, :max_duration, :call_limit, :cps_limit, :pdd_timeout, :ring_timeout,
                                  :lrn_source, :lrn_block, :force_cid, :decimal_points, :sip_trace, :block_wireless,
                                  :profit_margin_type, :try_timeout, :max_cost, :ingress_type, hosts_attributes: hosts_attributes])
  end
  
  def hosts_attributes
    [:id, :host_ip, :subnet, :port, :trunk_id, :trunk_type, :_destroy]
  end
  
  def load_egress_trunk
    @egress_trunk = EgressTrunk.find_by_id(params[:id])
    unless @egress_trunk
      flash[:error] = "Egress Trunk not found"
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end

  def update_status
    params[:enable].present? ? true : false
  end

end
