RubyLLM.configure do |config|
  config.gemini_api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.dig(:gemini_api_key)
  config.default_model = "gemini-2.5-flash"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
