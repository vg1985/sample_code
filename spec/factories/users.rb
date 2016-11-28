# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :email do |c|
    "test#{c}@mailinator.com"
  end
  factory :user do
    name "Test user"
    email
    password 'password'
  end
end
