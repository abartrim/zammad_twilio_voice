Zammad::Application.routes.draw do
  match '/api/v1/twilio/:token/call',     to: 'integration/twilio#call',    via: :post
  match '/api/v1/twilio/:token/events',     to: 'integration/twilio#events',    via: :post
  match '/api/v1/twilio/:token/status',     to: 'integration/twilio#status',    via: :post
end
