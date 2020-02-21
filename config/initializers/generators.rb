Rails.application.config.generators do |g|
  # Don't generate per-scaffolded-model assets
  g.stylesheets     false
  g.javascripts     false
  # Don't generate jbuilder views on scaffold
  # https://github.com/rails/jbuilder/blob/821f514741a3e9102082a6e98eb59a08671f75d0/lib/generators/rails/scaffold_controller_generator.rb#L9
  g.jbuilder        false
  # Don't generate helper with scaffold
  g.helper          false
end
