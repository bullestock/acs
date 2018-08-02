class LogsController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def new
  end

  def create
    logger.info "logs.create"
    @log = Log.new(log_params)

    @log.save
    redirect_to @log
  end


  def index
    # Apply the search control filter.
    logs_scope = Log.all
    filter_params = params[:filter]
    logs_scope = logs_scope.like(filter_params) if filter_params

    @logs = smart_listing_create :logs, logs_scope, partial: "logs/list", page_sizes: [100],
                                  sort_attributes: [[:stamp, "stamp"], [:user_id, "user_id"]],
                                  default_sort: {stamp: "desc"}
  end
  
  def show
    @log = Log.find(params[:id])
  end
end
