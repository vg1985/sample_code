module PaymentsHelper
  def payment_status_select
    [
      ["Pending", "pending"],
      ["Accepted", "accepted"],
      ["Declined", "declined"],
      ["Deleted (by admin)", "deleted"]
    ]
  end

  def payment_type_select
    [
      ["Wire/ACH", "wire"],
      ["Bank Deposit", "bank"],
      ["Paypal", "paypal"],
      ["Credit Card", "credit_card"]
    ]
  end

  def payment_type(val)
    types = { 
              "wire" => "Wire / ACH", 
              "bank" => "Bank Deposit",
              "paypal" => "Paypal",
              "credit_card" => "Credit Card",
              "charge" => "Charge"
            }
    return types[val]
  end
end
