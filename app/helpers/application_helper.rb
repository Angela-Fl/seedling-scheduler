# Global view helper methods for all controllers.
#
# This module is automatically included in all views.
# Add cross-cutting view logic here (formatting, shared UI components, etc.).
module ApplicationHelper
  def status_badge_class(status)
    case status
    when "new"
      "warning"
    when "reviewed"
      "info"
    when "done"
      "success"
    else
      "secondary"
    end
  end
end
