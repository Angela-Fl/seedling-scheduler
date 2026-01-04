class ApplicationMailer < ActionMailer::Base
  default from: "noreply@#{ENV.fetch('FLY_APP_NAME', 'seedling-scheduler')}.fly.dev"
  layout "mailer"
end
