require 'rails_helper'

RSpec.describe Host, type: :model do
  
  context "validations" do
    it { should validate_presence_of(:host_ip) }
    it { should validate_presence_of(:subnet) }
    it { should validate_presence_of(:port) }
  end
  
  context "associations" do
    it { should belong_to(:trunk) }
  end
  
end
