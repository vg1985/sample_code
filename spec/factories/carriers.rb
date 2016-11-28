FactoryGirl.define do
  sequence :company_name do |c|
    "Test#{c} company"
  end
  factory :carrier do
    company_name
  end
end
