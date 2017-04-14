class ApiLogsController < BaseApiController
  before_filter only: :create do
    unless @json.has_key?('log') && @json['log'].respond_to?(:[]) && @json['log']['message']
      render nothing: true, status: :bad_request
    end
  end

  def create
    a = @json['log']
    @log = Log.new
    @log.assign_attributes(a)
    @log.logger_id = @user.id
    if @json['log']['user_id']
      @log.user_id = @json['log']['user_id']
    end
    if @log.save
      render json: @log
    else
      render nothing: true, status: :bad_request
    end
  end
end
