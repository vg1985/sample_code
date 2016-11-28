require 'rails_helper'

RSpec.describe Routing, type: :model do
  
  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end
  
  context "associations" do
    it { should have_many(:ingress_trunks) }
  end
  
end
