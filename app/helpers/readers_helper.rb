module ReadersHelper
  def current_reader
    @current_reader ||= begin
      reader = Stripe::Terminal::Reader.retrieve(session[:current_reader_id])
      if !reader.deleted && reader.status == "online"
        reader
      else
        clear_reader
      end
    end
  rescue Stripe::InvalidRequestError
    clear_reader
  end

  def clear_reader
    session.delete(session[:current_reader_id])
    nil
  end
end
