source 'http://rubygems.org'

# Specify your gem's dependencies in performant.gemspec
gemspec

group :development, :test do
  gem "growl_notify"    # for guard
  gem "guard-rspec"
  gem "mongo",          require: false # XXX probably should move
  gem "rake"
  gem "rb-fsevent"      # for guard
  gem "rspec"
end

group :test do
  #em "ruby-debug19",   require: false
  gem "simplecov",      require: false
# gem "plymouth"        # invoke pry after rspec failures
end
