class DefaultSilentAuctionItemsToDraft < ActiveRecord::Migration[7.0]
  def change
    change_column_default :silent_auction_items, :status, from: "paused", to: "draft"
  end
end
