require 'csv'
require 'smarter_csv'
class RateSheet < ActiveRecord::Base
  #include RateSheetWrapper

  ## CONSTANTS ##
  US_JURISDICTION = 0
  US_NON_JURISDICTION = 1
  A_Z_JURISDICTION = 2

  JURISDICTION_TYPES = {US_JURISDICTION => 'US Jurisdiction', US_NON_JURISDICTION => 'US Non-Jurisdiction', A_Z_JURISDICTION => 'A-Z'}
  DT_ADMIN_COLS = ['name', 'count', 'lrn', 'rate_sheet_type', 'updated_at', 'notes']

  ## VALIDATIONS ##
  validates :name, :rate_sheet_type, presence: true
  validates :rate_sheet_type, inclusion: {in: JURISDICTION_TYPES.keys, allow_blank: true}
  validates :name, uniqueness: {allow_blank: true}

  ## ASSOCIATIONS ##
  has_many :ingress_trunks
  has_many :egress_trunks
  has_many :rates,  dependent: :delete_all
  has_many :rate_sheet_notifications, as: :rate_sheet
  has_many :user_actions, as: :trackable

  ## CLASS METHODS ##
  def self.for_select
    self.select('id, name').all.collect do |r|
      [r.name, r.id]
    end
  end

  ## INSTANCE METHODS ##
  def lrn_value
    lrn? ? "LRN" : "DNIS"
  end

  def to_csv(q = nil)
    if self.rate_sheet_type == US_JURISDICTION
      column_names = us_juri_colnames
    else
      column_names = non_us_juri_colnames
    end

    CSV.generate do |csv|
      csv << column_names
      if q.present?
        rates = self.rates.where(["rates.code LIKE ?", "%#{q}%"])
      else
        rates = self.rates
      end
      rates.each do |rate|
        csv << column_names.map{ |attr| rate.send(attr) }
      end
    end
  end

  def us_juri_colnames
    %w(code code_name code_country inter_rate intra_rate rate bill_start bill_increment effective_time setup_fee)
  end

  def non_us_juri_colnames
    %w(code code_name code_country rate bill_start bill_increment effective_time setup_fee)
  end

  def jd
    rate_sheet_type == "A-Z"
  end

  def import(csv_file, user_action_id, rounding)
    success_rows = 0
    failed_rows = 0
    user_action = UserAction.find(user_action_id)
    rates_obj = []

    begin
      csv = SmarterCSV.process(File.open(csv_file))
      #open('inserts.sql', 'w') do |f|
      open(File.join(Rails.root, 
                    'app', 
                    'downloads', 
                    'import_logs', 
                    "user_action_#{user_action.id}.log"
                    ), 'w') do |flog|

        #f << "INSERT INTO rates (user_action_id, status, info, created_at, updated_at) VALUES "
        csv.each_with_index do |row, index|
          #puts 'Processing row....' + index.to_s

          #progress indicator
          if(index%1000 == 0)
            progress = { 
              failed_rows: failed_rows, 
              processed_rows: success_rows
            }
            user_action.update_attributes(info: progress)
          end

          begin
            #Delayed::Worker.logger.info 'running without update...'
            rate = Rate.new(rate_sheet_id: self.id) 
            #rate = self.rates.find_or_initialize_by(code: row[:code], effective_time: row[:effective_time])
            
            rate.attributes = row
            rate.rate = rate.rate.ceil_to(rounding) if rate.rate > 0
            rate.inter_rate = rate.inter_rate.ceil_to(rounding) if rate.inter_rate > 0
            rate.intra_rate = rate.intra_rate.ceil_to(rounding) if rate.intra_rate > 0

            #rate.save!
            if rate.valid?
              success_rows += 1
              rates_obj << rate
            else
              failed_rows += 1
              flog.puts "Row##{index}: #{rate.errors.full_messages.join('; ')}"
              #msg = ActiveRecord::Base.connection.quote("#{{row_no: index, error: e.message}.to_yaml}")
              #f << "(150, 'some status', #{msg}, NOW(), NOW()),"
            end
          rescue => e
            #Rails.logger.info "ERROR : #{e.message}"
            #user_action.add_detail('failed_csv_row', {row_no: index, error: e.message})
            flog.puts "Row##{index}: #{e.message}"
            #msg = ActiveRecord::Base.connection.quote("#{{row_no: index, error: e.message}.to_yaml}")
            #f << "(150, 'some status', #{msg}, NOW(), NOW()),"
            failed_rows += 1
          end

          #flush rates into mysql and retain memory
          if(success_rows%10000 == 0)
            Rate.import rates_obj, validate: false
            rates_obj = []
          end
        end
      end #flog file end

      if success_rows.present?
        Rate.import rates_obj, validate: false
      end

      if failed_rows > 0 && success_rows > 0
        action_attrs = {status: 'partially_successful'}
      elsif failed_rows > 0 && success_rows < 1
        action_attrs = {status: 'failed'}
      else
        action_attrs = {status: 'successful'}        
      end
      
      action_attrs[:info] = {total_rows: failed_rows + success_rows, 
                              failed_rows: failed_rows, 
                              successful_rows: success_rows}
      action_attrs[:finished_at] = DateTime.now                              

      user_action.update_attributes(action_attrs)
    rescue => e
      user_action.update_attributes(status: 'failed', info: {error: e.message}, finished_at: DateTime.now)
    end
  end

  def import_with_update(csv_file, user_action_id, rounding)
    success_rows = 0
    failed_rows = 0
    user_action = UserAction.find(user_action_id)

    begin
      csv = SmarterCSV.process(File.open(csv_file))
      #open('inserts.sql', 'w') do |f|
      open(File.join(Rails.root, 
                    'app', 
                    'downloads', 
                    'import_logs', 
                    "user_action_#{user_action.id}.log"
                    ), 'w') do |flog|

        #f << "INSERT INTO rates (user_action_id, status, info, created_at, updated_at) VALUES "
        csv.each_with_index do |row, index|
          #puts 'Processing row....' + index.to_s

          #progress indicator
          if(index%1000 == 0)
            progress = { 
              failed_rows: failed_rows, 
              processed_rows: success_rows
            }
            user_action.update_attributes(info: progress)
          end

          begin
            rate = self.rates.where(code: row[:code]).order('created_at DESC').first

            if rate.blank?
              rate = Rate.new(rate_sheet_id: self.id) 
            end
            
            #rate = self.rates.find_or_initialize_by(code: row[:code], effective_time: row[:effective_time])
            
            rate.attributes = row
            rate.rate = rate.rate.ceil_to(rounding) if rate.rate > 0
            rate.inter_rate = rate.inter_rate.ceil_to(rounding) if rate.inter_rate > 0
            rate.intra_rate = rate.intra_rate.ceil_to(rounding) if rate.intra_rate > 0

            #rate.save!
            if rate.valid?
              success_rows += 1
              rate.save(validate: false)
            else
              failed_rows += 1
              flog.puts "Row##{index}: #{rate.errors.full_messages.join('; ')}"
              #msg = ActiveRecord::Base.connection.quote("#{{row_no: index, error: e.message}.to_yaml}")
              #f << "(150, 'some status', #{msg}, NOW(), NOW()),"
            end
          rescue => e
            #Rails.logger.info "ERROR : #{e.message}"
            #user_action.add_detail('failed_csv_row', {row_no: index, error: e.message})
            flog.puts "Row##{index}: #{e.message}"
            #msg = ActiveRecord::Base.connection.quote("#{{row_no: index, error: e.message}.to_yaml}")
            #f << "(150, 'some status', #{msg}, NOW(), NOW()),"
            failed_rows += 1
          end
        end
      end #flog file end

      if failed_rows > 0 && success_rows > 0
        action_attrs = {status: 'partially_successful'}
      elsif failed_rows > 0 && success_rows < 1
        action_attrs = {status: 'failed'}
      else
        action_attrs = {status: 'successful'}        
      end
      
      action_attrs[:info] = {total_rows: failed_rows + success_rows, 
                              failed_rows: failed_rows, 
                              successful_rows: success_rows}
      action_attrs[:finished_at] = DateTime.now                              

      user_action.update_attributes(action_attrs)
    rescue => e
      user_action.update_attributes(status: 'failed', info: {error: e.message}, finished_at: DateTime.now)
    end
  end

  ## PRIVATE METHODS ##
  private
  def valid_headers(headers)
    (headers && ["code", "rate", "bill_start", "bill_increment"]).blank? ? false : true
  end

end
