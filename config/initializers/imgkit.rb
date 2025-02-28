# Configure IMGKit for HTML to image conversion
IMGKit.configure do |config|
  # Use the bundled wkhtmltoimage binary
  config.wkhtmltoimage = Gem.bin_path('wkhtmltoimage-binary', 'wkhtmltoimage')
  
  # Set default options
  config.default_options = {
    width: 1200,
    height: 630,
    quality: 90,
    disable_smart_width: true
  }
end