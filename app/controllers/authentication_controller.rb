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
      session[:current_user_id] = @user.id
      if @user.admin?
        redirect_to :root, notice: "Successfully logged in"
      else
        redirect_to pos_main_path, notice: "Successfully logged in"
      end
    else
      redirect_to sign_in_path, alert: "Incorrect PIN"
    end
  end

  def destroy
    session.delete(:current_user_id)
    session.delete(:current_reader_id)
    redirect_to sign_in_path, notice: "Successfully logged out"
  end
end
