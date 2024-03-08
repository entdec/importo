module Satis
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    def create_initializer_file
      template "config/initializers/satis.rb"
    end

    def add_route
      return if Rails.application.routes.routes.detect { |route| route.app.app == Satis::Engine }
      route %(mount Satis::Engine => "/satis")
    end

    def copy_migrations
      rake "satis:install:migrations"
    end

    def tailwindcss_config
      rake "satis:tailwindcss:config"
    end
  end
end
