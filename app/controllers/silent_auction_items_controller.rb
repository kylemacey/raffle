class SilentAuctionItemsController < ApplicationController
  before_action -> { require_permission!("silent_auction.manage") }
  before_action :set_event
  before_action :set_item, only: %i[
    show edit update open pause close close_confirmation retry_invoice
    promote_winner_confirmation promote_winner
  ]
  before_action :ensure_invoice_mutable!, only: %i[
    edit update open pause close close_confirmation retry_invoice
    promote_winner_confirmation promote_winner
  ]

  def index
    @items = @event.silent_auction_items
                   .includes(:invoice_record, :winning_bid, :silent_auction_bids)
                   .ordered_for_admin
    @open_all_count = mutable_items.where(status: %w[draft paused]).count
    @pause_all_count = mutable_items.where(status: "open").count
    @close_all_count = mutable_items.where(status: %w[open paused]).count
  end

  def show
    @bids = @item.silent_auction_bids.order(amount_cents: :desc, created_at: :asc)
  end

  def new
    @item = @event.silent_auction_items.build
  end

  def create
    @item = @event.silent_auction_items.build(item_params)

    if @item.save
      redirect_to event_silent_auction_item_path(@event, @item), notice: "Silent auction item was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to event_silent_auction_item_path(@event, @item), notice: "Silent auction item was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def open
    return redirect_to event_silent_auction_item_path(@event, @item), alert: "Closed items cannot be reopened." if @item.closed?

    @item.update!(status: "open")
    redirect_to event_silent_auction_item_path(@event, @item), notice: "Silent auction item is open."
  end

  def pause
    return redirect_to event_silent_auction_item_path(@event, @item), alert: "Closed items cannot be paused." if @item.closed?

    @item.update!(status: "paused")
    redirect_to event_silent_auction_item_path(@event, @item), notice: "Silent auction item is paused."
  end

  def open_all
    count = mutable_items.where(status: %w[draft paused]).update_all(status: "open", updated_at: Time.current)
    redirect_to event_silent_auction_items_path(@event), notice: "#{count} silent auction item#{'s' unless count == 1} opened."
  end

  def pause_all
    count = mutable_items.where(status: "open").update_all(status: "paused", updated_at: Time.current)
    redirect_to event_silent_auction_items_path(@event), notice: "#{count} silent auction item#{'s' unless count == 1} paused."
  end

  def close_confirmation
    @winning_bid = @item.current_bid
    @invoice_setting = InvoiceSetting.current
  end

  def close_all_confirmation
    @items = @event.silent_auction_items
                   .where(status: %w[open paused])
                   .includes(:silent_auction_bids, :invoice_record)
                   .ordered_for_admin
                   .reject(&:paid_invoice?)
    @invoice_setting = InvoiceSetting.current
  end

  def close
    result = SilentAuction::CloseItemService.new(@item).call
    redirect_to event_silent_auction_item_path(@event, @item), flash_for_result(result)
  end

  def close_all
    result = SilentAuction::CloseEventItemsService.new(@event).call
    redirect_to event_silent_auction_items_path(@event), flash_for_result(result)
  end

  def retry_invoice
    result = SilentAuction::CloseItemService.new(@item).call
    redirect_to event_silent_auction_item_path(@event, @item), flash_for_result(result)
  end

  def promote_winner_confirmation
    @bid = @item.silent_auction_bids.find(params[:bid_id])
    @invoice = @item.invoice_record
    @invoice_setting = InvoiceSetting.current
  end

  def promote_winner
    bid = @item.silent_auction_bids.find(params[:bid_id])
    result = SilentAuction::CloseItemService.new(@item, winning_bid: bid, replace_invoice: true).call
    redirect_to event_silent_auction_item_path(@event, @item), flash_for_result(result)
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_item
    @item = @event.silent_auction_items.find(params[:id])
  end

  def item_params
    params.require(:silent_auction_item).permit(
      :name,
      :description,
      :formatted_starting_bid,
      :image_url
    )
  end

  def ensure_invoice_mutable!
    return unless @item.paid_invoice?

    redirect_to event_silent_auction_item_path(@event, @item), alert: "Paid invoices cannot be changed."
  end

  def mutable_items
    @event.silent_auction_items
          .left_outer_joins(:invoice_record)
          .where("invoice_records.id IS NULL OR ((invoice_records.stripe_status IS NULL OR invoice_records.stripe_status != ?) AND invoice_records.paid_at IS NULL)", "paid")
  end

  def flash_for_result(result)
    result.success? ? { notice: result.message } : { alert: result.message }
  end
end
