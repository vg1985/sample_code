require 'rails_helper'

RSpec.describe EgressTrunk, type: :model do

  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:carrier) }
    it { should validate_presence_of(:depth) }
  end

  context "association" do
    it { should belong_to(:carrier) }
    it { should belong_to(:rate_sheet) }
    it { should have_many(:hosts) }
  end

  context "enum" do

    let(:egress_trunk) {FactoryGirl.build(:egress_trunk)}

    it "should return routing strategies for Egress trunks" do
      expect(EgressTrunk.routing_strategies).to eq({"Round Robin" => 0, "Top Down" => 1})
      egress_trunk.routing_strategy = 0
      expect(egress_trunk.routing_strategy).to eq("Round Robin")
      egress_trunk.routing_strategy = 1
      expect(egress_trunk.routing_strategy).to eq("Top Down")
    end
  end

end
