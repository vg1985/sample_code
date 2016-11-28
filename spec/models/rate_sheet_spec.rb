require 'rails_helper'

RSpec.describe RateSheet, type: :model do
  
  context "validations" do
    it { should validate_presence_of(:name) }
  end
  
  context "associations" do
    it { should have_many(:ingress_trunks) }
    it { should have_many(:egress_trunks) }
  end
  
end
