module AuthenticationHelper
  def current_user
    @current_user ||= User.find_by(id: session[:current_user_id])
  end

  def authenticated?
    !!current_user
  end

  def current_user_is_admin?
    !!current_user&.admin?
  end

  def require_admin!
    current_user_is_admin? || redirect_to(:root, notice: "Not authorized")
  end
end
