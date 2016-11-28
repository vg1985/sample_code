module CarriersHelper
  def toggleswitch_init_format(did_rate)
    return [true, true, true, true, true, false] if did_rate.blank?
    
    did_rate.to_arr.collect do |dr|
      dr.nil? ? true : false
    end
  end
  
  def spinner_init_values(did_rate)
    return ['null', 'null', 'null', 'null', 'null'] if did_rate.blank?
    
    did_rate.to_arr.collect do |dr|
      dr.nil? ? 'null' : dr
    end
  end
  
  def po_toggle_init(carrier) 
    return [true, true, true] if carrier.new_record?
    
    [:allow_cc, :allow_paypal, :allow_paypal_ipn].collect do |attr|
      carrier.try(attr)
    end
  end

  def contacts_dirty_values(carrier)
    carrier.contacts.collect do |contact|
      [contact.id, contact.name, contact.email, contact.mobile]
    end
  end

  def invoice_due_options
    {
      'On Receipt': :receipt, 
      'Net 7': :net7, 
      'Net 10': :net10, 
      'Net15': :net15, 
      'Net30': :net30 
    }
  end
end
