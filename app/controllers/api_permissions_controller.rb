class ApiPermissionsController < BaseApiController
  before_filter only: :show do
    unless @json.has_key?('card_id')
      render nothing: true, status: :bad_request
    end
  end

  def show
    if !@machine
      render nothing: true, status: :forbidden
    else
      user = User.find_by_card_id(params[:card_id])
      if !user
        logger.info "User not found"
        render nothing: true, status: :not_found
      else
        logger.info "User ID: #{user.id} #{user.name}"
        is_allowed = user.machines.map(&:name).include?(@machine.name)
        logger.info "Allowed: #{is_allowed}"
        render json: {
	  'allowed' => is_allowed, 
	  'id' => user.id,
	  'name' => user.name
	}
      end
    end
  end
end
