class AuthenticationController < ApplicationController
  def new
  end

  def create
    if @user = User.find_by(pin: params[:pin])
      session[:current_user_id] = @user.id
      redirect_to :root, notice: "Successfully logged in"
    else
      redirect_to sign_in_path, alert: "Incorrect PIN"
    end
  end

  def destroy
    session.delete(:current_user_id)
    session.delete(:current_reader_id)
    redirect_to :root, notice: "Successfully logged out"
  end
end
