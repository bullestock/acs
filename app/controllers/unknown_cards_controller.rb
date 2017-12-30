class UnknownCardsController < ApplicationController
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
    uc_scope = UnknownCard.all_with_filter(params, UnknownCard.all)

    @unknown_cards = smart_listing_create :unknown_cards, uc_scope, partial: "unknown_cards/list", page_sizes: [100],
                                          sort_attributes: [[:stamp, "stamp"], [:card_id, "card_id"]],
                                          default_sort: {stamp: "desc"}
  end
  
  def show
    @unknown_card = UnknownCard.find(params[:card_id])
  end
end
