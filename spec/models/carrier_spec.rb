require 'rails_helper'

RSpec.describe Carrier do

  let(:carrier) {FactoryGirl.create(:carrier)}

  context "validation" do
    before do
      @carrier = FactoryGirl.create(:carrier)
    end
    it { should validate_presence_of(:company_name) }
    it "should validate uniqueness of account_code" do
      @carrier.account_code = carrier.account_code
      @carrier.valid?
      expect(@carrier.errors[:account_code]).not_to be_blank
    end
    it "should validate numericality of account_code" do
      @carrier.account_code = "abc"
      @carrier.valid?
      expect(@carrier.errors[:account_code]).not_to be_blank
    end
  end
  
  context "association" do
    it { should belong_to(:user) }
    it { should belong_to(:reseller) }
    it { should have_many(:contacts) }
    it { should have_many(:ingress_trunks) }
    it { should have_many(:egress_trunks) }
    it { should have_many(:admins_carriers) }
    it { should have_many(:admins) }
  end
  
  context "callbacks" do
    
    it "should generate account code before validation" do
      @carrier = Carrier.new
      @carrier.valid?
      expect(@carrier.account_code).not_to be_nil
    end
    
  end
  
end
