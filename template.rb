
def apply_template!
  add_template_repository_to_source_path

  @passenger_user = app_name.camelize.downcase
  @passenger_user = ask("Enter the username running passenger") if no? %{Do you want to keep "#{@passenger_user}" as the username running passenger?}

  copy_templates
  install_nix
  install_nixops
  intial_commit
  install_sidekiq
  install_dotenv
  install_passenger
  install_capistrano
  install_sentry
  install_redis
  install_devise
  install_misc
end

def install_devise
  gem 'devise'
  gem 'geocoder'
  gem 'authtrail'
  gem 'ahoy_matey'

  inject_into_file 'config/environments/development.rb', after: 'config.active_storage.service = :local' do <<EOS


  config.action_mailer.smtp_settings = {address: "localhost", port: 1025}
  config.action_mailer.default_url_options = {host: "localhost", port: 3000}
EOS
  end
end

def install_redis
  gem 'redis', '~> 4.0'
end

def install_sentry
  gem "sentry-raven"
  sentry_dsn = ask("Enter a sentry dsn")
  sentry_dsn = 'http://public@example.com/project-id' if sentry_dsn.empty?
  initializer "sentry.rb", <<-EOS
    Raven.configure do |config|
      config.dsn = '#{sentry_dsn}'
    end
  EOS
end

def install_capistrano
  gem 'capistrano', require: false
  gem "capistrano-rails", require: false
  gem 'capistrano-env', require: false
  gem 'capistrano-master-key', github: 'JoeDupuis/capistrano-master-key',require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-sidekiq', require: false
  copy_file "Capfile"
  FileUtils.mkdir_p Rails.root.join('lib', 'capistrano', 'tasks')
  FileUtils.touch(Rails.root.join('lib', 'capistrano', 'tasks', '.keep'))
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
  template ".env.development.tt"
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
