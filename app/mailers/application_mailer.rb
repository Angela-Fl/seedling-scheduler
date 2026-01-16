class ApplicationMailer < ActionMailer::Base
  default from: "noreply@seedlingscheduler.com"
  layout "mailer"

  before_action :cancel_delivery_to_demo_users

  private

  def cancel_delivery_to_demo_users
    recipient = params[:user] || params[:resource]
    if recipient.respond_to?(:demo?) && recipient.demo?
      mail.perform_deliveries = false
    end
  end
end
