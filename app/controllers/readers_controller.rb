class ReadersController < ApplicationController
  include ReadersHelper

  def list
    @readers = Stripe::Terminal::Reader.list(status: :online)
    if Rails.env.development?
      @locations = Stripe::Terminal::Location.list(limit: 100)
    end
  end

  def assign
    session[:current_reader_id] = params[:reader_id]
    redirect_to readers_list_path
  end

  def create_simulated
    if Rails.env.development?
      begin
        Stripe::Terminal::Reader.create({
          registration_code: 'simulated-wpe',
          location: params[:location_id],
          label: "Simulated Reader - #{params[:location_id]}"
        })
        flash[:notice] = "Simulated reader created successfully."
      rescue Stripe::StripeError => e
        flash[:alert] = "Error creating simulated reader: #{e.message}"
      end
    else
      flash[:alert] = "Simulated readers can only be created in the development environment."
    end
    redirect_to readers_list_path
  end

  def cancel_action
    current_reader&.cancel_action
    redirect_to controller: :pos, action: :main
  end
end
