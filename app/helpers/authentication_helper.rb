module AuthenticationHelper
  def current_user
    @current_user ||= User.find_by(id: session[:current_user_id])
  end
  alias_method :set_current_user, :current_user

  def authenticated?
    !!current_user
  end

  def current_user_can?(permission_key)
    current_user&.has_permission?(permission_key)
  end

  def current_user_can_any?(*permission_keys)
    permission_keys.flatten.any? { |permission_key| current_user_can?(permission_key) }
  end

  def current_user_can_view_order?(order)
    return false unless current_user
    return true if current_user_can?("orders.view_all")
    return true if current_user_can?("orders.view_own") && order.user_id == current_user.id

    current_user_can?("orders.view_event") &&
      session[:current_event_id].present? &&
      order.event_id == session[:current_event_id].to_i
  end

  def require_authentication!
    return true if authenticated?

    redirect_to(sign_in_path, notice: "You must sign in first")
    false
  end

  def require_permission!(*permission_keys)
    return false unless require_authentication!
    return true if current_user_can_any?(permission_keys)

    redirect_to(default_authorization_failure_path, alert: "Not authorized")
    false
  end

  def default_after_sign_in_path
    return pos_main_path if current_user_can?("pos.sell")
    return events_path if current_user_can?("events.view")
    return users_path if current_user_can?("users.manage")

    sign_in_path
  end

  def default_authorization_failure_path
    return pos_main_path if current_user_can?("pos.sell")
    return events_path if current_user_can?("events.view")

    sign_in_path
  end
end
