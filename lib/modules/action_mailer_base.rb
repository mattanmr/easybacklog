class ActionMailerBase < ActionMailer::Base
  default :from => ENV.fetch('DEFAULT_FROM_EMAIL', 'easyBacklog <no-reply@localhost.test>')
end
