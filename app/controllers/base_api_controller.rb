class BaseApiController < ActionController::Base
  #protect_from_forgery with: :null_session

  before_action :destroy_session
  before_filter :parse_request, :authenticate_machine_from_token!

  def destroy_session
    request.session_options[:skip] = true
  end
  
  private
  def authenticate_machine_from_token!
    if !@json['api_token']
      logger.info "No authentication token in #{@json}"
      render nothing: true, status: :unauthorized
    else
      logger.info "Authentication token is #{@json['api_token']}"
      @machine = nil
      Machine.find_each do |m|
        if m.api_token == @json['api_token']
          @machine = m
          logger.info "Found machine #{m.name}"
        end
      end
    end
  end

  def parse_request
    @json = JSON.parse(request.body.read)
  end
end
