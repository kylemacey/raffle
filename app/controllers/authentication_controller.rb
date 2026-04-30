class AuthenticationController < ApplicationController
  def new
  end

  def create
    pin = params[:pin]

    # Validate PIN format
    unless pin&.match?(/\A\d{4}\z/)
      redirect_to sign_in_path, alert: "PIN must be exactly 4 digits"
      return
    end

    if @user = User.find_by(pin: pin)
      clear_session_context!
      session[:current_user_id] = @user.id
      redirect_to default_after_sign_in_path, notice: "Successfully logged in"
    else
      redirect_to sign_in_path, alert: "Incorrect PIN"
    end
  end

  def destroy
    clear_session_context!
    redirect_to sign_in_path, notice: "Successfully logged out"
  end

  private

  def clear_session_context!
    session.delete(:current_user_id)
    session.delete(:current_event_id)
    session.delete(:current_event_user_id)
    session.delete(:current_reader_id)
  end
end
