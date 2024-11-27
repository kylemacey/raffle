class PosController < ApplicationController
  include PosHelper
  include ReadersHelper

  before_action :require_authentication!

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

      Payment.create!(
        entry: entry,
        payment_method_type: "cash",
        amount: RaffleProduct.custom_price(params[:tickets].to_i),
      )

      redirect_to pos_success_path(entry_id: entry.id)
    end

    if params[:payment_method] == "card"
      payment_service = CollectPaymentService.new(
        customer: {
          name: params[:name],
          email: params[:email],
        },
        reader: current_reader,
      )

      payment_service.collect_payment(
        RaffleProduct.custom_price(params[:tickets].to_i),
        metadata: {
          event: current_event.id,
          name: params[:name],
          email: params[:email],
          qty: params[:tickets],
          agent: current_user.name,
        }
      )

      if payment_service.success?
        redirect_to(
          controller: :pos,
          action: :wait_for_pin_pad,
          payment_intent_id: payment_service.payment_intent.id
        )

      end
    end
  end

  def wait_for_pin_pad
    @payment_intent = Stripe::PaymentIntent.retrieve(params[:payment_intent_id])

    respond_to do |format|
      format.html # Render the initial HTML view
      format.turbo_stream # Respond with a Turbo Stream if requested
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
