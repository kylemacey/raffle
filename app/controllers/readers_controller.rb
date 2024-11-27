class ReadersController < ApplicationController
  include ReadersHelper

  def list
    @readers = Stripe::Terminal::Reader.list(status: :online)
  end

  def assign
    session[:current_reader_id] = params[:reader_id]
    redirect_to readers_path
  end

  def cancel_action
    current_reader&.cancel_action
    redirect_to controller: :pos, action: :main
  end
end
