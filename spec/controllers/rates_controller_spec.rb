require 'rails_helper'

RSpec.describe RatesController, type: :controller do

  before do
    sign_in
  end

  describe "update" do

    before do
      @rate = FactoryGirl.create(:rate)
      @params = {"rate_sheet_id" => "1", "code" => "123"}
      allow(Rate).to receive(:find_by_id).with("1").and_return(@rate)
      allow(@rate).to receive(:update_attributes).and_return(true)
    end

    describe "success" do

      it "should find rate with id" do
        expect(Rate).to receive(:find_by_id).with("1").and_return(@rate)
      end

      it "should update attributes of rate" do
        expect(@rate).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, { rate: @params, id: "1", format: :json }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end

end
