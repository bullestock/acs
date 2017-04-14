class ApiPermissionsController < BaseApiController
  before_filter only: :show do
    unless @json.has_key?('permission') && @json['permission'].respond_to?(:[]) && @json['permission']['machine']&& @json['permission']['card_id']
      render nothing: true, status: :bad_request
    end
  end

  def show
    user = User.find_by_card_id(params[:permission][:card_id])
    if !user
      logger.info "User not found"
      render nothing: true, status: :not_found
    else
      logger.info "User ID: #{user.id} #{user.name}"
      is_allowed = user.machines.map(&:name).any? { |s| s.casecmp(params[:permission][:machine]) == 0 }
      logger.info "Allowed: #{is_allowed}"
      render json: { 'allowed' => is_allowed }
    end
  end
end
