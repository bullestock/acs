class ApiLogsController < BaseApiController
  before_filter only: :create do
    unless @json.has_key?('log') && @json['log'].respond_to?(:[]) && @json['log']['message']
      logger.info "Rejected by filter"
      render nothing: true, status: :bad_request
    end
  end

  def create
    if !@machine
      logger.info "Machine not found"
      render nothing: true, status: :forbidden
    else
      a = @json['log']
      @log = Log.new
      @log.assign_attributes(a)
      @log.logger_id = @machine.id
      if @json['log']['user_id']
        @log.user_id = @json['log']['user_id']
      end
      if @log.save
        render json: @log
      else
        logger.info "Could not save log entry"
        render nothing: true, status: :bad_request
      end
    end
  end

  def show
    if !@machine
      logger.info "Machine not found"
      render nothing: true, status: :forbidden
    else
      @log = Log.where("logger_id = #{@machine.id}").order("id desc")
      if @json['user_id']
        @log = @log.where("user_id = #{@json['user_id']}")
      end
      if @json['last']
        @log = @log.limit(@json['last'])
      end
      render json: @log
    end
  end
end
