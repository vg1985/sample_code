require 'rails_helper'

describe PagesController do
  
  describe "index" do
    
    before do
      sign_in
    end
    
    it "should render dashboard" do
      get :index
      expect(response).to be_success
      expect(response).to render_template('index')
    end
    
  end
  
end
