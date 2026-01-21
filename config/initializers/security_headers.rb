# Security Headers Configuration
# This initializer adds security headers to protect against common web vulnerabilities

Rails.application.config.action_dispatch.default_headers.merge!(
  # Prevent clickjacking attacks by preventing the site from being framed
  'X-Frame-Options' => 'SAMEORIGIN',
  
  # Enable XSS protection in browsers that support it
  'X-XSS-Protection' => '1; mode=block',
  
  # Prevent MIME type sniffing
  'X-Content-Type-Options' => 'nosniff',
  
  # Referrer policy - only send origin when navigating to other origins
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  
  # Permissions policy - restrict access to browser features
  'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()'
)

# Content Security Policy
# NOTE: 'unsafe-inline' and 'unsafe-eval' are currently required for legacy Rails 3.2 compatibility
# TODO: When upgrading Rails, implement nonce-based or hash-based CSP to remove these directives
# This helps prevent XSS attacks by specifying which sources are allowed
if Rails.env.production?
  Rails.application.config.action_dispatch.default_headers['Content-Security-Policy'] = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.cloudfront.net",  # TODO: Remove unsafe-* with Rails upgrade
    "style-src 'self' 'unsafe-inline' *.cloudfront.net",                  # TODO: Remove unsafe-inline with Rails upgrade
    "img-src 'self' data: *.cloudfront.net",
    "font-src 'self' *.cloudfront.net easybacklog.com",
    "connect-src 'self'",
    "frame-ancestors 'self'",
    "base-uri 'self'",
    "form-action 'self'"
  ].join('; ')
end
