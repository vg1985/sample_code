require 'rails_helper'

RSpec.describe Reseller do
  
  context "validation" do
    it { should validate_presence_of(:name) }
  end
  
  context "association" do
    it { should have_many(:carriers) }
  end
  
end
