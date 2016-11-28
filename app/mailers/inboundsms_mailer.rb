class InboundsmsMailer < ActionMailer::Base
  default from: proc{ Setting.outboundsms_settings.outbound_sms_email }
  include ActionView::Helpers::TextHelper
  register_interceptor InboundsmsSettingsInterceptor

  def forward(to, body, subject)
    mail(to: to,
         body: simple_format(body),
         subject: subject.html_safe,
         content_type: 'text/html')
  end
end
