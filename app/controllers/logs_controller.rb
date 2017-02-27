class LogsController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def new
  end

  def index
    # Apply the search control filter.
    filter_params = params[:filter]
    if filter_params
      filter_params = { 'message' => { 'idx' => { 'o' => 'like', 'v' => filter_params } } }
      params[:filter] = filter_params
    end
    logs_scope = Log.all_with_filter(params, Log.all)

    @logs = smart_listing_create :logs, logs_scope, partial: "logs/list", page_sizes: [100],
                                  sort_attributes: [[:stamp, "stamp"], [:machine_id, "machine_id"]],
                                  default_sort: {stamp: "desc"}
  end
  
  def show
    @log = Log.find(params[:id])
  end
end
