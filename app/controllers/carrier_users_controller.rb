class CarrierUsersController < ApplicationController

  before_filter :load_user, only: :update

  def new
    @user = User.new
    @carrier = @user.build_carrier
  end

  def create
    @user = User.create(user_params)
    render :save
  end

  def update
    @user.update_attributes(user_params)
    render :save
  end

  private
  def user_params
    params[:user].permit(:id, :name, :email, :password, :token, carrier_attributes: carrier_attributes)
  end

  def carrier_attributes
    [:id, :company_name, :address1, :address2, :city, :state, :zip, :country, :phone1, :phone2, :mobile, :timezone, :account_code, :user_id]
  end

  def load_user
    @user = User.find_by_id(params[:id])
    unless @user
      return render "shared/not_found"
    end
  end

end
