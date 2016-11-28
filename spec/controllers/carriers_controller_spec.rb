require 'rails_helper'

RSpec.describe CarriersController, type: :controller do

  before do
    sign_in
  end

  describe "index" do

    before do
      @carrier = FactoryGirl.create(:carrier)
    end

    describe "success" do

      it "should assign all carriers" do
        expect(Carrier).to receive(:includes).with(:user).and_return([@carrier])
      end

      after do
        get :index
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end

  describe "edit" do

    before do
     @carrier = FactoryGirl.build(:carrier)
     allow(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
    end

    describe "success" do

      it "should find carrier with id" do
        expect(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      end

      after do
        get :edit, id: "1"
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end

  describe "update" do

    before do
      @carrier = FactoryGirl.build(:carrier)
      @params = {"company_name" => "railsmancer", "account_code" => "456789123"}
      allow(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      allow(@carrier).to receive(:update_attributes).and_return(true)
    end

    describe "success" do

      it "should find carrier with id" do
        expect(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      end

      it "should update attributes of carrier" do
        expect(@carrier).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, { carrier: @params, id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end
  
  describe "activate" do
    
    before do
      @carrier = FactoryGirl.build(:carrier)
      allow(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      allow(@carrier).to receive(:update_attribute).and_return(true)
    end
    
    describe "success" do
      
      it "should find carrier with id" do
        expect(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      end
      
      it "should update attribute of carrier" do
        expect(@carrier).to receive(:update_attribute).with(:is_active, true).and_return(true)
      end
      
      after do
        xhr :get, :activate, { carrier: @params, id: "1"}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
    
  end
  
  describe "deactivate" do
    
    before do
      @carrier = FactoryGirl.build(:carrier)
      allow(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      allow(@carrier).to receive(:update_attribute).and_return(true)
    end
    
    describe "success" do
      
      it "should find carrier with id" do
        expect(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      end
      
      it "should update attribute of carrier" do
        expect(@carrier).to receive(:update_attribute).with(:is_active, false).and_return(true)
      end
      
      after do
        xhr :get, :deactivate, { carrier: @params, id: "1", format: :js}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
    
  end
  
  describe "destroy" do
    
    before do
      @carrier = FactoryGirl.build(:carrier)
      allow(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      allow(@carrier).to receive(:destroy).and_return(true)
    end
    
    describe "success" do
      
      it "should find carrier with id" do
        expect(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      end

      it "should destroy carrier" do
        expect(@carrier).to receive(:destroy).and_return(true)
      end
      
      after do
        delete :destroy, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end
      
    end
    
  end
  
  describe "update_status_for_selected" do
    
    before do
      @carrier = FactoryGirl.create(:carrier)
      @carriers = Carrier.all
      allow(Carrier).to receive(:where).and_return(@carriers)
      allow(@carriers).to receive(:update_all).and_return(true)
    end
    
    describe "success" do
      
      it "should find carriers with id" do
        expect(Carrier).to receive(:where).with(id: ["2"]).and_return(@carriers)
      end
      
      it "should update status for carriers" do
        expect(@carriers).to receive(:update_all).with(is_active: false).and_return(true)
      end
      
      after do
        xhr :post, :update_status_for_selected, { carrier_ids: ["2"]}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
     
  end
  
  describe "egress trunks" do
    
    before do
      @carrier = FactoryGirl.build(:carrier)
      allow(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      allow(@carrier).to receive(:egress_trunks).and_return(@egress_trunks) 
    end
    
    describe "success" do
      
      it "should find carrier with id" do
        expect(Carrier).to receive(:find_by_id).with("1").and_return(@carrier)
      end
      
      it "should return associated egress trunks for carrier" do
        expect(@carrier).to receive(:egress_trunks).and_return(@egress_trunks) 
      end
      
      after do
        xhr :get, :egress_trunks, id: "1"
        expect(response).to be_success
        expect(response.status).to be(200)
      end
      
    end
    
  end

end
