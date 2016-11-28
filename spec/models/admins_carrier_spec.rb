require 'rails_helper'

RSpec.describe AdminsCarrier, type: :model do
  
  context "validations" do
    it { should validate_presence_of(:carrier_id) }
  end
  
  context "associations" do
    it { should belong_to(:admin) }
    it { should belong_to(:carrier) }
  end
  
end
