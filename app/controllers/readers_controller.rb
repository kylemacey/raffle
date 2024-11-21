class ReadersController < ApplicationController
  def list
    @readers = Stripe::Terminal::Reader.list(status: :online)
  end

  def assign
    session[:current_reader_id] = params[:reader_id]
    redirect_to readers_path
  end
end
