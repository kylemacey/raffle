module EventsHelper
  def grouped_events_for_dropdown
    events = Event.order(created_at: :desc)
    one_year_ago = 1.year.ago

    past_year_events, older_events = events.partition { |e| e.created_at >= one_year_ago }

    {
      past_year: past_year_events,
      older_five: older_events.first(5),
      show_older_events_section: older_events.any?
    }
  end
end
