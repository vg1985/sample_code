class ApplicationMailer < ActionMailer::Base
  default from: "admin@sipsurge.com"
  layout 'mailer'

  register_interceptor DynamicSettingsInterceptor
end
