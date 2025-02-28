# Configure IMGKit for HTML to image conversion
IMGKit.configure do |config|
  if Rails.env.production?
    # Use the system wkhtmltoimage in production
    config.wkhtmltoimage = '/usr/local/bin/wkhtmltoimage'
  else
    # Use the bundled wkhtmltoimage binary in development
    config.wkhtmltoimage = Gem.bin_path('wkhtmltoimage-binary', 'wkhtmltoimage')
  end
  
  # Set default options
  config.default_options = {
    width: 1200,
    height: 630,
    quality: 90,
    disable_smart_width: true
  }
end