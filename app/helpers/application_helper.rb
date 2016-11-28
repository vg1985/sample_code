module ApplicationHelper
  def carrier
    current_user.carrier
  end
  
  def setup_new_obj(obj, assoc)
    obj.send(assoc) || obj.send("build_#{assoc.to_s}")
  end

  def setup_objects(obj, assoc)
    obj.send(assoc).present? ? obj.send(assoc) : obj.send(assoc).build
  end

  def carrier_form_url(user)
    user.new_record? ? carrier_users_path : carrier_user_path(user)
  end
  
  def admin_form_url(user)
    user.new_record? ? admins_path : admin_path(user)
  end

  def return_status(status)
    status.present? ? "Active" : "Inactive"
  end

  def return_boolean(val)
    val ? "Yes" : "No"
  end

  def select_options(klass, method)
    klass.all.collect{|k| [k.send(method), k.id]}
  end

  def return_form_obj(condition)
    if condition
      { user: (@carrier.user || @user) }
    else
      { carrier: @carrier }
    end
  end

  def active_class(controllers, actions=[])
    if actions.present?
      return 'active' if controllers.include?(params[:controller]) && actions.include?(params[:action])
    else
      return 'active' if controllers.include?(params[:controller])
    end
  end

  def active_subnav_class(controllers, actions=[])
    if actions.present?
      return 'dblock' if controllers.include?(params[:controller]) && actions.include?(params[:action])
    else
      return 'dblock' if controllers.include?(params[:controller])
    end
  end

  def new_active_class(urls_for, dblock=false)
    if urls_for.include?("#{params[:controller]}##{params[:action]}") ||
       urls_for.include?("#{params[:controller]}")

       dblock ? 'dblock' : 'active'
    end
  end

  def sms_ratesheet_url(ratesheet_type, action)
    case action
    when "new"
      new_sell_ratesheet_path
    when "index"
      ratesheet_type == SellRatesheet ? sell_ratesheets_path : buy_ratesheets_path
    when "template"
      ratesheet_type == SellRatesheet ? template_sell_ratesheets_path : template_buy_ratesheets_path
    end
  end

  def obj_sms_ratesheet_url(ratesheet_type, action, obj)
    case action
    when "edit"
      edit_sell_ratesheet_path(obj)
    when "delete"
      sell_ratesheet_path(obj)
    when "show"
      ratesheet_type == SellRatesheet ? sell_ratesheet_path(obj) : buy_ratesheet_path(obj)
    when "logs"
      ratesheet_type == SellRatesheet ? logs_sell_ratesheet_path(obj) : logs_buy_ratesheet_path(obj)
    when "search"
      ratesheet_type == SellRatesheet ? search_sell_ratesheet_path(obj) : search_buy_ratesheet_path(obj)
    when "export"
      ratesheet_type == SellRatesheet ? export_sell_ratesheet_path(obj) : export_buy_ratesheet_path(obj)
    when "import"
      ratesheet_type == SellRatesheet ? import_sell_ratesheet_path(obj) : import_buy_ratesheet_path(obj)
    end
  end

  def titleize(klass)
    klass.to_s.underscore.humanize.titleize
  end

  def vendors_select
    [
      ["Bandwidth", "BW"],
      ["Nexmo", "NX"],
      ["VI", "VI"],
      ["AZ", "AZ"],
      ["MS", "MS"],
      ["DL", "DL"]
    ]
  end

  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name) 
    # replace all none alphanumeric, underscore or periods
    # with underscore
    just_filename.sub(/[^\w\.\-]/,'_') 
 end
 
  def get_roles
    Role.visible.all.collect{|role| [role.name, role.id]}
  end

  def invoice_billing_options
    { 
      'Weekly': Carrier::BILLING_CYCLE_WEEKLY, 
      'Monthly': Carrier::BILLING_CYCLE_MONTHLY 
    }
  end

end
