require 'rails/generators/base'

module Satis
  module Generators
    class TailwindConfigGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)
      desc 'Configures tailwind.config.js and application.tailwindcss.css'

      def add_content_to_tailwind_config
        inject_into_file "config/tailwind.config.js", before: "],\n  theme: {" do
          "  // Satis content\n" +
            %w[/app/views/**/* /app/helpers/**/* /app/controllers/**/* /app/components/**/* /app/javascript/**/*.js /app/assets/**/*.css].map { |path| "    \"#{Satis::Engine.root}#{path}\"" }.join(",\n") +
            ",\n  "
        end
      end

      def add_content_application_tailwind_css
        inject_into_file "app/assets/stylesheets/application.tailwind.css", before: "@tailwind base;" do
          "@import '#{Satis::Engine.root}/app/assets/stylesheets/satis/application.css';\n"
        end
      end
    end
  end
end
