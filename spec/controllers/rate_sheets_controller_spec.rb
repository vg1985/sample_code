require 'rails_helper'

RSpec.describe RateSheetsController, type: :controller do

  before do
    sign_in
  end

  describe "index" do
    
    before do
      @rate_sheet = FactoryGirl.build(:rate_sheet)
      allow(RateSheet).to receive(:all).and_return(@rate_sheets)
    end

    describe "success" do

      it "should assign all rate sheets" do
        expect(RateSheet).to receive(:all).and_return(@rate_sheets)
      end

      after do
        get :index
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end

  describe "new" do
    
    before do
      @rate_sheet = FactoryGirl.build(:rate_sheet)
      allow(RateSheet).to receive(:new).and_return(@rate_sheet)
    end

    describe "success" do

      it "should assign new parameters" do
        expect(RateSheet).to receive(:new).and_return(@rate_sheet)
      end

      after do
        get :new
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end

  describe "create" do
    
     before do
        @rate_sheet = FactoryGirl.build(:rate_sheet)
       @params = {"name" => "abc", "rate_sheet_id" => "1"}
       allow(RateSheet).to receive(:create).and_return(@rate_sheet)
     end

     describe "success" do

       it "should create new rate sheet" do
         expect(RateSheet).to receive(:create).and_return(@rate_sheet)
       end

       after do
         post :create, { rate_sheet: @params, format: :js }
         expect(response).to be_success
         expect(response).to render_template(:save)
       end

     end
 
  end

  describe "destroy" do

    before do
      @rate_sheet = FactoryGirl.build(:rate_sheet)
      allow(RateSheet).to receive(:find_by_id).and_return(@rate_sheet)
      allow(@rate_sheet).to receive(:destroy).and_return(true)
    end

    describe "success" do

      it "should find rate sheet trunk with id" do
        expect(RateSheet).to receive(:find_by_id).with("1").and_return(@rate_sheet)
      end

      it "should delete rate sheet" do
        expect(@rate_sheet).to receive(:destroy).and_return(true)
      end

      after do
        delete :destroy, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end

  describe "edit" do

    before do
      @rate_sheet = FactoryGirl.build(:rate_sheet)
      allow(RateSheet).to receive(:find_by_id).and_return(@rate_sheet)
    end

    describe "success" do

      it "should find rate sheet trunk with id" do
        expect(RateSheet).to receive(:find_by_id).with("1").and_return(@rate_sheet)
      end

      after do
        get :edit, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end

  describe "update" do
    
    before do
      @rate_sheet = FactoryGirl.build(:rate_sheet)
      @params = {"name" => "abc", "rate_sheet_id" => "1"}
      allow(RateSheet).to receive(:find_by_id).and_return(@rate_sheet)
      allow(@rate_sheet).to receive(:update_attributes).and_return(true)
    end

    describe "success" do

      it "should find rate sheet trunk with id" do
        expect(RateSheet).to receive(:find_by_id).with("1").and_return(@rate_sheet)
      end

      it "should update rate sheet attributes" do
        expect(@rate_sheet).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, { rate_sheet: @params, id: "1", format: :js }
        expect(response).to be_success
        expect(response).to render_template(:save)
      end

    end

  end
  
  describe "show" do
    
    before do
      @rate_sheet = FactoryGirl.build(:rate_sheet)
      @rates = @rate_sheet
      allow(RateSheet).to receive(:find_by_id).and_return(@rate_sheet)
      allow(@rate_sheet).to receive(:rates).and_return(@rates)
    end

    describe "success" do

      it "should find rate sheet trunk with id" do
        expect(RateSheet).to receive(:find_by_id).with("1").and_return(@rate_sheet)
      end

      it "should return rates associated to this ratesheet" do
        expect(@rate_sheet).to receive(:rates).and_return(@rates)
      end

      after do
        get :show, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end

end
