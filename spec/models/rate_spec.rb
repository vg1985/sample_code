require 'rails_helper'

RSpec.describe Rate, type: :model do

  context "validations" do
    it { should validate_numericality_of(:rate) }
    it { should validate_numericality_of(:inter_rate) }
    it { should validate_numericality_of(:intra_rate) }
    it { should validate_numericality_of(:bill_start) }
    it { should validate_numericality_of(:bill_increment) }
    it { should validate_numericality_of(:setup_fee) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:effective_time) }
  end

  context "associations" do
    it { should belong_to(:rate_sheet) }
  end

end
