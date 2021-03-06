
def apply_template!
  add_template_repository_to_source_path

  @server_user = app_name.camelize.downcase
  @server_user = ask("Enter the username of the user running the app on the production server") if no? %{Do you want to keep "#{@server_user}" as the username running the app on the production server?}

  @warning_messages = []

  copy_templates
  install_locales
  install_nix
  install_nixops
  install_sidekiq
  install_dotenv
  install_capistrano
  install_sentry
  install_redis
  install_devise
  install_datagrid
  install_misc
  install_js

  setup_style
  setup_base_app

  setup_credentials

  misc_config

  setup_tests

  intial_commit

  warning_messages
  after_bundle do
    # Repeat messages after bundle to make extra sure they are read
    warning_messages
  end
end

def install_js
  directory 'app/javascript/controllers'

end

def setup_style
  FileUtils.rm_rf "app/assets/stylesheets/application.css"
  directory "app/assets"
end

def setup_credentials
  directory 'config/credentials'
  append_file ".gitignore", "config/credentials/*.key"
end

def setup_base_app
  directory "app/views/application"
  directory "app/controllers/concerns"
  directory "app/assets/images"
  template "app/views/layouts/application.html.erb.tt"
  copy_file "app/helpers/application_helper.rb"
  template "config/database.yml.tt"
  template "README.md.tt"
  directory "config/initializers"

  FileUtils.touch 'dev_notes.md'
end

def setup_tests
  inject_into_file "test/test_helper.rb", before: 'class ActiveSupport::TestCase' do
    %{Dir[Rails.root.join("test/models/concerns/**/*test.rb")].each { |f| require f }\n\n}
  end
end

def install_datagrid
  gem "datagrid", "~> 1.5"
  gem "kaminari"
  directory "app/views/datagrid"
  directory "app/grids"
end

def install_locales
  copy_file "config/locales/devise.ca_fr.yml"
  copy_file "config/locales/default.ca_fr.yml"
  copy_file "config/locales/99.ca_fr.yml"
  copy_file "config/locales/99.en.yml"
  copy_file "config/locales/datagrid.en.yml"
  copy_file "config/locales/datagrid.ca_fr.yml"
  FileUtils.rm_rf 'config/locales/en.yml'
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
  after_bundle do
    generate 'ahoy:install'
  end
  environment "config.action_mailer.default_url_options = { host: ENV['DEFAULT_URL_OPTIONS_HOST'] }", env: :production
  environment %{config.action_mailer.smtp_settings = {address: "localhost", port: 1025}\n  config.action_mailer.default_url_options = {host: "localhost", port: 3000}\n}, env: :development

  directory 'app/views/devise'

  after_bundle do
    generate "devise:install"
    generate "devise user"
  end

  push_warning "Change the devise module in the user model and update the user migration before running it."
  push_warning "Change config.mailer_sender in devise initializer."
  push_warning "Do not forget to change DEFAULT_URL_OPTIONS_HOST in .env.production"
  push_warning "Ensure you have defined root_url to *something* in your config/routes.rb."
end

def install_redis
  gem 'redis', '~> 4.0'
  template 'config/cable.yml.tt'
end

def install_sentry
  gem "sentry-raven"
  initializer "sentry.rb", <<-EOS
    Raven.configure do |config|
    end
  EOS

  push_warning "Do not forget to change SENTRY_DSN in .env.production"
end

def install_capistrano
  gem 'capistrano', require: false
  gem "capistrano-rails", require: false
  gem 'capistrano-env', require: false
  gem 'capistrano-master-key', github: 'JoeDupuis/capistrano-master-key',require: false
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
  gem 'capistrano-passenger', require: false
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
  append_file ".gitignore", ".env.local"
  append_file ".gitignore", ".env.test.local"
  append_file ".gitignore", ".env.development.local"
  append_file ".gitignore", ".env.production.local"
  append_file ".gitignore", ".env.staging.local"
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
  template "shell.nix.tt"
  template "default.nix.tt"
  directory "nix"
end

def install_nixops
  template "nixops/default.nix.tt"
  template "nixops/provider/libvirtd.nix.tt"
  template "nixops/provider/vbox.nix.tt"

  push_warning "Do not forget to set db user and db name in nixops/default.nix (or pass them as parameters)"
end

def intial_commit
  after_bundle do
    git :init
    git add: "."
    git commit: '-m "Initial commit"'
  end
end

def misc_config
  environment "config.hosts << ENV['DEV_HOST'] if ENV['DEV_HOST'].present?"
end

def copy_templates
  copy_file "lib/templates/rails/scaffold_controller/controller.rb.tt"
  copy_file "lib/templates/erb/scaffold/show.html.erb.tt"
  copy_file "lib/templates/erb/scaffold/new.html.erb.tt"
  copy_file "lib/templates/erb/scaffold/index.html.erb.tt"
  copy_file "lib/templates/erb/scaffold/_form.html.erb.tt"
  copy_file "lib/templates/erb/scaffold/edit.html.erb.tt"
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
