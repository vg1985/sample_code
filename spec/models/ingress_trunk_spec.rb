require 'rails_helper'

RSpec.describe IngressTrunk, type: :model do
  
  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:carrier) }
    it { should validate_presence_of(:reg_user) }
    it { should validate_presence_of(:reg_password) }
  end
  
  context "associations" do
    it { should belong_to(:carrier) }
    it { should belong_to(:rate_sheet) }
    it { should belong_to(:routing) }
    it { should have_many(:hosts) }
  end

  context "enum" do

    let(:ingress_trunk) {FactoryGirl.build(:ingress_trunk)}

    it "should return lrn sources for Ingress trunks" do
      expect(IngressTrunk.lrn_sources).to eq({"LRN Server" => 0, "SIP Header" => 1})
      ingress_trunk.lrn_source = 0
      expect(ingress_trunk.lrn_source).to eq("LRN Server")
      ingress_trunk.lrn_source = 1
      expect(ingress_trunk.lrn_source).to eq("SIP Header")
    end

    it "should return ingress_types for Ingress trunks" do
      expect(IngressTrunk.ingress_types).to eq({"Registration" => 0, "IP Authentication" => 1})
      ingress_trunk.ingress_type = 0
      expect(ingress_trunk.ingress_type).to eq("Registration")
      ingress_trunk.ingress_type = 1
      expect(ingress_trunk.ingress_type).to eq("IP Authentication")
    end
  end

end
