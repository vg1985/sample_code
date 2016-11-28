class RatesController < ApplicationController
  after_action :verify_authorized
  before_filter :load_rate, except: [:index, :new, :create, :check_code, :bulk_destroy]

  def update
    authorize @rate

    @rate.update_attributes(rate_params)

    if @rate.rate_sheet.rate_sheet_type == RateSheet::US_JURISDICTION
      @data = [@rate.code, @rate.code_name, @rate.code_country, @rate.inter_rate.to_s, @rate.intra_rate.to_s, @rate.rate.to_s, 
              @rate.bill_start.to_s, @rate.bill_increment.to_s, @rate.setup_fee.to_s, @rate.effective_time]
    else 
      @data = [@rate.code, @rate.code_name, @rate.code_country, @rate.rate.to_s, 
              @rate.bill_start.to_s, @rate.bill_increment.to_s, @rate.setup_fee.to_s, @rate.effective_time]
    end

    if @rate.errors.any?
      UserAction.log(@rate.rate_sheet, current_user.id, 'rate_update', 'failed', { Code: @rate.code })
    else
      UserAction.log(@rate.rate_sheet, current_user.id, 'rate_update', 'successful', { Code: @rate.code })
    end

    respond_to do |format|
      format.js
    end
  end

  def create
    @rate = Rate.new(rate_params)

    authorize @rate

    @rate_sheet = @rate.rate_sheet

    if @rate.save
      UserAction.log(@rate_sheet, current_user.id, 'rate_created', 'successful', { Code: @rate.code })
      @message = 'Rate has been saved successfully.'
    else
      logger.info 'errors.......' + @rate.errors.full_messages.inspect
      UserAction.log(@rate_sheet, current_user.id, 'rate_created', 'failed', { Code: @rate.code })
      @error = 'Operation could not be performed due to invalid fields.'
    end

    get_rates

    respond_to do |format|
      format.js { render 'index' }
    end
  end

  def destroy
    authorize @rate
    @rate.destroy
    get_rates

    @message = 'Rate has been deleted successfully'
    @rate_sheet = @rate.rate_sheet

    UserAction.log(@rate_sheet, current_user.id, 'rate_removed', 'successful', { Code: @rate.code })

    respond_to do |format|
      format.js { render 'index' }
    end
  end

  def bulk_destroy
    authorize Rate.new, :destroy?
    
    rates = Rate.where(id: params[:rate_ids])
    @rate_sheet = rates.first.rate_sheet

    rates.destroy_all
    @rates = Rate.where(rate_sheet_id: @rate_sheet.id).order(session['rates']['order_by']).page(params[:page]).per(session['rates']['per_page'])
    
    UserAction.log(@rate_sheet, current_user.id, 'bulk_delete', 'successful', {Count: rates.size})

    @message = 'Selected rates have been deleted successfully'

    render :index
  end

  def check_code
    skip_authorization

    @rate = Rate

    if params[:id].to_i > 0
      @rate = @rate.where(["id != ?", params[:id]])
    end

    @rate = @rate.where(code: params[:name], 
                        rate_sheet_id: params[:rid]).limit(1)
                        #effective_time: params[:eff_time]).limit(1)
    
    respond_to do |format|
      format.json { render :json => @rate.blank? }
    end
  end

  private
  def rate_params
    params.permit(:id, :rate_sheet_id, :code, :code_name, :code_country, :inter_rate, :intra_rate, 
                  :rate, :bill_start, :bill_increment, :setup_fee, :rate_sheet_id, :effective_time)
  end

  def load_rate
    @rate = Rate.find_by_id(params[:id])
    unless @rate
      flash[:error] = "Rate not found"
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end

  def get_rates
    @rates = Rate.where(rate_sheet_id: @rate.rate_sheet_id).order(session['rates']['order_by']).page(params[:page]).per(params[:per])
  end

end
