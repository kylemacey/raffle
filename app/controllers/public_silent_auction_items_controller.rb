class PublicSilentAuctionItemsController < ApplicationController
  skip_before_action :require_basic_auth
  before_action :set_event

  layout "silent_auction"

  def index
    @items = @event.silent_auction_items
                   .publicly_listed
                   .includes(:silent_auction_bids)
                   .ordered_for_public
  end

  def show
    @item = @event.silent_auction_items.publicly_listed.find(params[:id])
    @bid = @item.silent_auction_bids.build
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
