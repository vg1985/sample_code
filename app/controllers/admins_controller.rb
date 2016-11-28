class AdminsController < ApplicationController
  
  before_filter :load_user, except: [:index, :new, :create]
  
  def index
    @admins = user_scope.all
  end
  
  def new
    @user = user_scope.new
  end
  
  def create
    @user = user_scope.create(user_params)
    render :save
  end
  
  def edit
  end
  
  def update
    @user.update_attributes(user_params)
    render :save
  end
  
  def destroy
    @user.destroy
  end
  
  def method_name
    somearray.each do |el|
      
    end
  end

  private
  def user_params
    params[:user].merge!({role_id: Role.admin_id})
    params[:user][:carrier_ids] = params[:user][:carrier_ids].select{|i| i.present?} if params[:user][:carrier_ids].present?
    params[:user].permit(:id, :name, :username, :email, :password, :role_id, carrier_ids: [])
  end
  
  def load_user
    @user = user_scope.find_by_id(params[:id])
    unless @user
      return render "shared/not_found"
    end
  end

  def user_scope
    User.admins
  end
  
end
