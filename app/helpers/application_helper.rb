module ApplicationHelper
  include StripeHelper

  def container_class
    @full_width_container ? 'container-fluid px-2' : 'container'
  end
end
