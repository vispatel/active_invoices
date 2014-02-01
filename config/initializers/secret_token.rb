# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActiveInvoices::Application.config.secret_token = ENV['SECRET_TOKEN'] || '6d8cbf47ee9e30e90c5c5216ad0310349e95effc057a6459a627bad0e6397b874b8bb4689435dae18f9b045c7fee3d028822381513dae6f20d588d0069dc94e1'
