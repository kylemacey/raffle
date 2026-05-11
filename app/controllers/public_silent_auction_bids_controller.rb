class PublicSilentAuctionBidsController < ApplicationController
  skip_before_action :require_basic_auth
  before_action :set_event

  layout "silent_auction"

  def create
    @item = @event.silent_auction_items.where(status: "open").find(params[:silent_auction_item_id])

    @item.with_lock do
      @item.reload
      @bid = @item.silent_auction_bids.build(bid_params)
      @bid.minimum_bid_cents = @item.next_minimum_bid_cents
      @bid.save
    end

    if @bid.persisted?
      redirect_to event_public_silent_auction_item_path(@event, @item), notice: "Bid placed."
    else
      render "public_silent_auction_items/show", status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def bid_params
    params.require(:silent_auction_bid).permit(
      :bidder_name,
      :bidder_phone,
      :bidder_email,
      :formatted_amount,
      :commitment_confirmation
    )
  end
end
