class MasqueradesController < Devise::MasqueradesController
	
  def show
    allowed = policy(:user_action).masquerade?

    if !allowed
      if policy(:carrier).masquerade? && current_user.allowed_carriers.present? &&
         User.find(params[:id]).is_carrier?

        if current_user.allowed_carriers.include?('-10')
          allowed = true
        else
          user_ids = Carrier.find(current_user.allowed_carriers).collect(&:user_id)
          allowed = user_ids.include?(params[:id].to_i)
        end
      end
    end
    
    unless allowed
    	respond_to do |format|
        flash[:error] = 'You are not authorized to perform this action.'
        format.html { redirect_to root_url and return }
        format.js { render json: 'Not Authorized' and return } 
      end
    end
    
    super
  end
end