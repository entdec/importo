desc 'Release a new version'
namespace :importo do
  task :release do
    version_file = './lib/importo/version.rb'
    File.open(version_file, 'w') do |file|
      file.puts <<~EOVERSION
        # frozen_string_literal: true

        module Importo
          VERSION = '#{Importo::VERSION.split('.').map(&:to_i).tap { |parts| parts[2] += 1 }.join('.')}'
        end
      EOVERSION
    end
    module Importo
      remove_const :VERSION
    end
    load version_file
    puts "Updated version to #{Importo::VERSION}"

    `git commit lib/importo/version.rb -m "Version #{Importo::VERSION}"`
    `git push`
    `git tag #{Importo::VERSION}`
    `git push --tags`
  end
end
