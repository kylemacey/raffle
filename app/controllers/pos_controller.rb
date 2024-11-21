class PosController < ApplicationController
  include PosHelper
  include ReadersHelper

  def new
    @events = Event.all
  end

  def create
    session[:current_event_id] = params[:event_id]
    redirect_to pos_main_path
  end

  def main
    @products = RaffleProduct.all
  end

  def checkout
    unless current_event
      redirect_to pos_path
    end

    if params[:payment_method] == "cash"
      entry = Entry.create!(
        name: params[:name],
        phone: params[:email],
        qty: params[:tickets],
        event: current_event,
      )

      redirect_to pos_success_path(entry_id: entry.id)
    end

    if params[:payment_method] == "card"
      CollectPaymentService.call(
        amount: RaffleProduct.custom_price(params[:tickets].to_i),
        customer: {
          name: params[:name],
          email: params[:email],
        },
        reader: current_reader,
        metadata: {
          event: current_event.name,
          agent: current_user.name,
        }
      )
    end
  end

  def create_order

  end

  def success
    @entry = Entry.find(params[:entry_id])
  end

  # Turbo Action
  def custom_price
    tickets = params[:tickets].to_i
    price = RaffleProduct.custom_price(tickets)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("custom_price", partial: "pos/custom_price", locals: { price: price })
      end
    end
  end
end
