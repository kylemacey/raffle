class SilentAuctionSettingsController < ApplicationController
  before_action -> { require_permission!("invoice_settings.manage") }

  def edit
    @setting = SilentAuctionSetting.current
  end

  def update
    @setting = SilentAuctionSetting.current

    if @setting.update(setting_params)
      redirect_to edit_silent_auction_setting_path, notice: "Silent auction settings were updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:silent_auction_setting).permit(:formatted_bid_increment)
  end
end
