module PosHelper
  def current_event
    @current_event ||= Event.find_by(id: session[:current_event_id])
  end
end
