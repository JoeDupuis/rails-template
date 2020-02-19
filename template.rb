
def apply_template!
  add_template_repository_to_source_path

  copy_templates
  install_nix
  install_nixops
  intial_commit
  install_sidekiq
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
