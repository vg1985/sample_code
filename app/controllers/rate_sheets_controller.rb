class RateSheetsController < ApplicationController
  after_action :verify_authorized

  before_filter :load_rate_sheet, except: [:index, :new, :create, :template, :check_name, :dt_ratesheets_interplay]

  def index
    authorize RateSheet.new
    @rate_sheets = RateSheet.order('id DESC').all
  end

  def dt_ratesheets_interplay
    authorize RateSheet.new, :index?

    filter_query = {}
    filter_query[:lrn] = params[:columns]['2']['search']['value'] if params[:columns]['2']['search']['value'].present?
    filter_query[:rate_sheet_type] = params[:columns]['3']['search']['value'] if params[:columns]['3']['search']['value'].present?

    select_clause = 'rate_sheets.id, rate_sheets.name, rate_sheets.lrn, rate_sheets.rate_sheet_type, rate_sheets.notes, rate_sheets.updated_at'

    search_filter = ['rate_sheets.name LIKE ? OR rate_sheets.notes LIKE ?', 
                      "%#{params["search"]["value"]}%", "%#{params["search"]["value"]}%"]

    order_by = "#{RateSheet::DT_ADMIN_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"

    @rate_sheets = RateSheet.where(filter_query).select(select_clause).order(order_by)

    if params["search"]["value"].present?
      @rate_sheets = @rate_sheets.where(search_filter)
    end

    @rate_sheets = @rate_sheets.page(params[:page]).per(params[:length])

    @data = @rate_sheets.collect do |ratesheet|
      [ ERB::Util.html_escape(ratesheet.name), ratesheet.rates.count, ratesheet.lrn?, 
        RateSheet::JURISDICTION_TYPES[ratesheet.rate_sheet_type], 
        ratesheet.updated_at.in_time_zone(current_user.timezone).to_s(:carrier),
        ERB::Util.html_escape(ratesheet.notes), ratesheet.id]
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    @rate_sheet = RateSheet.new

    authorize @rate_sheet
  end

  def create
    @rate_sheet = RateSheet.create(rate_sheet_params)

    authorize @rate_sheet

    respond_to do |format|
      format.html { 
        if @rate_sheet.save
          flash[:notice] = 'Rate sheet has been successfully created'
        else
          flash[:error] = 'Rate sheet could not be created due to error while saving.'
          logger.info 'errors........' + @rate_sheet.errors.full_messages.inspect
        end

        redirect_to rate_sheets_path
      }
    end
  end

  def show
    authorize @rate_sheet

    if session['rates'].blank? || !request.xhr?
      session['rates'] = {'order_by' => 'code ASC', 'per_page' => '20'}
    end
    
    session['rates']['order_by'] = params[:order] || session['rates']['order_by']
    session['rates']['per_page'] = params[:per_page] || session['rates']['per_page']
    

    if params[:q].present?
      @rates = @rate_sheet.rates.where(["rates.code LIKE ?", "%#{params[:q]}%"])
    else
      @rates = @rate_sheet.rates
    end

    @rates = @rates.order(session['rates']['order_by']).page(params[:page]).per(session['rates']['per_page'])
    #@rate_sheet_id = @rate_sheet.id

    respond_to do |format|
      format.html
      format.js {  render 'rates/index' }
    end
  end

  def edit
    authorize @rate_sheet
  end

  def update
    authorize @rate_sheet

    @rate_sheet.update_attributes(rate_sheet_params)

    if @rate_sheet.errors.any?
      logger.info 'errors.....' + @rate_sheet.errors.full_messages.inspect
      flash[:error] = 'Rate sheet could not be created due to error while updating.'
    else
      flash[:notice] = 'Rate sheet has been successfully updated'
    end

    redirect_to rate_sheets_path
  end

  def destroy
    authorize @rate_sheet

    @rate_sheet.destroy
  end

  def template
    skip_authorization

    if params[:type] == '0'
      send_file "#{Rails.root}/app/downloads/rate_template_0.csv", type: 'text/csv; charset=UTF-8;'
    else
      send_file "#{Rails.root}/app/downloads/rate_template.csv", type: 'text/csv; charset=UTF-8;'
    end
  end

  def export
    authorize @rate_sheet
    
    UserAction.log(@rate_sheet, current_user.id, 'exported', 'successful', { Ratesheet: @rate_sheet.name })

    send_data @rate_sheet.to_csv(params[:q]), 
              filename: "export#{@rate_sheet.name.gsub(' ', '').camelize}.csv", 
              type: 'text/csv; charset=UTF-8;'
  end

  def import
    authorize @rate_sheet

    if params[:file].present? && 
      (params[:file].content_type == 'text/csv' || params[:file].content_type == 'application/x-csv') &&
      (params[:file].size <= APP_CONFIG["max_csv_file_size"])

      params[:decimal_precision] = params[:decimal_precision].blank? ? 6 : params[:decimal_precision].to_i

      if params[:decimal_precision] < 1
        params[:decimal_precision] = 1
      elsif params[:decimal_precision] > 6
        params[:decimal_precision] = 6
      end
        
      user_action = UserAction.log(@rate_sheet, current_user.id, 'import_csv', 'processing', nil)
      #RateSheetWorker.perform_async('import_csv', @rate_sheet.id, 
       #                             params[:file].tempfile.path, 
        #                            {'delete_all': params[:import_option].to_i == 2},
         #                           user_action.id)
      RatesheetImportJob.perform_later(@rate_sheet.id, 
                                    params[:file].tempfile.path, 
                                    {
                                      'delete_all': params[:import_option].to_i == 2,
                                      'with_update': params[:import_option].to_i == 3,
                                      'rounding': params[:decimal_precision]
                                    },
                                    user_action.id)
      #@rate_sheet.import(params[:file].tempfile.path, user_action.id)
      flash[:notice] = 'The CSV Import is under process and its status will be updated shorty.'
      
      respond_to do |format|
        format.html {redirect_to polymorphic_url([@rate_sheet, UserAction]) and return }
        format.json { render json: {status: 'success', url: polymorphic_url([@rate_sheet, UserAction])} }
      end
    else
      flash[:error] = "Cannot process. No file or invalid file uploaded. 
                      File should have CSV contents and should not exceed 
                      #{ActiveSupport::NumberHelper.number_to_human_size(APP_CONFIG["max_csv_file_size"]) }"

      respond_to do |format|
        format.html { redirect_to @rate_sheet and return }
        format.json { render json: {status: 'success', url: rate_sheet_path(@rate_sheet)} }
      end
    end
  end

  def logs
    @logs = @rate_sheet.rate_sheet_notifications
  end

  def mass_update
    authorize @rate_sheet

    if params[:bulk_edit][:rate_ids].present?
      @rates = @rate_sheet.rates.where(id: params[:bulk_edit][:rate_ids].split(','))
    else
      @rates = @rate_sheet.rates              
    end

    begin
      @round_off = params[:bulk_edit][:decimal_precision].present? ? params[:decimal_rounding_val].to_i : 6
      
      set_clause = generate_set_clause

      #logger.info(set_clause)
      logger.info 'set clause...' + set_clause.join(',')
      @rates.update_all(set_clause.join(','))
      @message = 'Rates have been updated successfully'
      UserAction.log(@rate_sheet, current_user.id, 'batch_update', 'successful', { Ratesheet: @rate_sheet.name })

    rescue => e
      @error = "Records can't be updated. Error => #{e.message}"
      UserAction.log(@rate_sheet, current_user.id, 'batch_update', 'failed', { Ratesheet: @rate_sheet.name })
    end

    @rates = @rate_sheet.rates.order(session['rates']['order_by']).page(params[:page]).per(session['rates']['per_page'])

    respond_to do |format|
      format.html
      format.js {  render 'rates/index' }
    end
  end

  def empty
    authorize RateSheet.new, :destroy?
    
    @rate_sheet.rates.clear

    flash[:notice] = "#{@rate_sheet.name} has been emptied successfully."

    redirect_to @rate_sheet
  end

  def check_name
    skip_authorization

    @rate_sheet = RateSheet

    if params[:id].to_i > 0
      @rate_sheet = @rate_sheet.where(["id != ?", params[:id]])    
    end

    @rate_sheet = @rate_sheet.where(name: params[:rate_sheet][:name]).limit(1)
    
    respond_to do |format|
      format.json { render :json => @rate_sheet.blank? }
    end
  end

  private
  def rate_sheet_params
    params[:rate_sheet].permit(:id, :name, :lrn, :rate_sheet_type, :notes)
  end

  def load_rate_sheet
    @rate_sheet = RateSheet.find_by_id(params[:id])
    unless @rate_sheet
      flash[:error] = "Ratesheet not found"
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end

  def generate_set_clause
    clause = []
    %w(rate intra_rate inter_rate).each do |column|
      if params[:bulk_edit][column].present? || params[:bulk_edit][:decimal_precision].present?
        if params[:bulk_edit][column] == '4'
          clause << calculate_val(column, params[:bulk_edit][column], params["#{column}_mval"], @round_off)
        else
          clause << calculate_val(column, params[:bulk_edit][column], params["#{column}_val"], @round_off)
        end
      end
    end

    %w(bill_start bill_increment setup_fee effective_time).each do |column|
      if params[:bulk_edit][column].present?
        if ('setup_fee' == column) 
          if params[:bulk_edit][column] == '4'
            clause << calculate_val(column, params[:bulk_edit][column], params["#{column}_mval"], 4)
          else
            clause << calculate_val(column, params[:bulk_edit][column], params["#{column}_val"], 4)
          end
        else
          clause << calculate_val(column, params[:bulk_edit][column], params["#{column}_val"], nil)
        end
      end
    end

    clause
  end

  def calculate_val(column, action, value, round_to)
    case action.to_i
    when Rate::EDIT_ADD
      if round_to.nil?
        "#{column} = #{column} + #{value.to_i}"
      else
        "#{column} = " + Rate.round_off_sql("#{column} + #{value.to_f}", round_to)
      end
    when Rate::EDIT_SUBTRACT
      if round_to.nil?
        "#{column} = #{column} - #{value.to_i}"
      else
        "#{column} = " + Rate.round_off_sql("#{column} - #{value.to_f}", round_to)
      end
    when Rate::EDIT_MULTIPLY
      if round_to.nil?
        "#{column} = #{column} * #{value.to_i}"
      else
        "#{column} = " + Rate.round_off_sql("#{column} * #{value.to_f}", round_to)
      end
    when Rate::EDIT_SET_TO
      if round_to.nil?
        "#{column} = '#{value}'"
      else
        "#{column} = " + Rate.round_off_sql("#{value.to_f}", round_to)
      end
    else
      "#{column} = " + Rate.round_off_sql(column, round_to)
    end
  end

end