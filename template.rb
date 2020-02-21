
def apply_template!
  add_template_repository_to_source_path

  @passenger_user = app_name.camelize.downcase
  @passenger_user = ask("Enter the username running passenger") if no? %{Do you want to keep "#{@passenger_user}" as the username running passenger?}

  @warning_messages = []

  copy_templates
  install_locales
  install_nix
  install_nixops
  install_sidekiq
  install_dotenv
  install_passenger
  install_capistrano
  install_sentry
  install_redis
  install_devise
  install_misc

  setup_base_app

  setup_credentials

  intial_commit
  warning_messages
def setup_credentials
  directory 'config/credentials'
  append_file ".gitignore", "config/credentials/*.key"
end

def setup_base_app
  template "app/views/layouts/application.html.erb.tt"
  copy_file "app/views/application/_empty.html.erb"
  template "app/helper/application_helper.rb.tt"
end
end

def install_locales
  copy_file "config/locales/devise.ca_fr.yml"
  copy_file "config/locales/default.ca_fr.yml"
  copy_file "config/locales/99.ca_fr.yml"
  copy_file "config/locales/99.en.yml"
  FileUtils.rm 'config/locales/en.yml'
end

def push_warning warning
  @warning_messages << warning
end

def warning_messages
  puts "============================================="
  @warning_messages.each do |message|
    puts
    warn message
    puts
  end
  puts "============================================="
end

def install_devise
  gem 'devise'
  gem 'geocoder'
  gem 'authtrail'
  gem 'ahoy_matey'
  inject_into_file 'config/environments/production.rb', after: 'config.i18n.fallbacks = true' do
    "\n\n  config.action_mailer.default_url_options = { host: ENV['DEFAULT_URL_OPTIONS_HOST'] }"
  end

  inject_into_file 'config/environments/development.rb', after: 'config.active_storage.service = :local' do
  %{\n\n  config.action_mailer.smtp_settings = {address: "localhost", port: 1025}\n  config.action_mailer.default_url_options = {host: "localhost", port: 3000}}
  end


  template "app/views/layouts/application.html.erb.tt"
  template "app/helper/application_helper.rb.tt"

  after_bundle do
    generate "devise:install"
  end

  push_warning "Change config.mailer_sender in devise initializer."
  push_warning "Do not forget to change DEFAULT_URL_OPTIONS_HOST in .env.production"
  push_warning "Ensure you have defined root_url to *something* in your config/routes.rb."
end

def install_redis
  gem 'redis', '~> 4.0'
end

def install_sentry
  gem "sentry-raven"
  initializer "sentry.rb", <<-EOS
    Raven.configure do |config|
      config.dsn = ENV['SENTRY_DSN']
    end
  EOS

  push_warning "Do not forget to change SENTRY_DSN in .env"
end

def install_capistrano
  gem 'capistrano', require: false
  gem "capistrano-rails", require: false
  gem 'capistrano-env', require: false
  gem 'capistrano-master-key', github: 'JoeDupuis/capistrano-master-key',require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-sidekiq', require: false
  copy_file "Capfile"
  FileUtils.mkdir_p 'lib/capistrano/tasks'
  FileUtils.touch 'lib/capistrano/tasks/.keep'
  template "config/deploy.rb.tt"
  template "config/deploy/staging.rb.tt"
  template "config/deploy/production.rb.tt"

  # after_bundle do
  #   run "bundle exec cap install"
  # end
end

def install_passenger
  gem "passenger", require: false, group: [:production]
  template "Passengerfile.json.tt"
end

def install_misc
  gem "standard", group: [:development, :test]
  gem "niceql", group: [:development, :test]
  #gem "scenic"
  #gem "fx"
  #gem "irbtools", require: "irbtools/binding", group: [:development]
end

def install_dotenv
  gem "dotenv-rails"
  template ".env.tt"
  template ".env.development.tt"
  template ".env.production.tt"
end

def install_sidekiq
  gem "sidekiq"
  initializer "sidekiq.rb", <<-EOS
    Rails.application.config.active_job.queue_adapter     = :sidekiq
    Rails.application.config.active_job.queue_name_prefix = "#{@app_name.underscore}"
  EOS
  template "config/sidekiq.yml.tt"
end


def install_nix
  copy_file "shell.nix"
  directory "nix"
end

def install_nixops
  template "nixops/default.nix.tt"
  template "nixops/provider/libvirtd.nix.tt"
  template "nixops/provider/vbox.nix.tt"
end

def intial_commit
  after_bundle do
    git :init
    git add: "."
    git commit: '-m "Initial commit"'
  end
end

def copy_templates
  copy_file "lib/templates/rails/scaffold_controller/controller.rb.tt"
end

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/mattbrictson/rails-template.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

apply_template!
