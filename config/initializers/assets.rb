# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( theme.js carriers.js inbound_dids.js settings.js orders.js 
												  inbound_dids_groups.js finance.js dropzone.css dropzone.min.js
												  carrier_settings.js custom.css trunk_groups.js otp_auth.js
												  routings.js ratesheets.js user_actions.js reports.js support.js
												  sms.js roles.js users.js bootstrap.min.js intl-tel-input.css
												  print-ticket.css, invoices.js
												)
