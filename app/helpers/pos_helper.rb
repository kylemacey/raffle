module PosHelper
  def current_event
    return unless current_event_selected_by_current_user?

    @current_event ||= Event.find_by(id: session[:current_event_id])
  end
end
