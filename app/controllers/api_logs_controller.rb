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
    if @log.save
      render json: @log
    else
      render nothing: true, status: :bad_request
    end
  end
end
