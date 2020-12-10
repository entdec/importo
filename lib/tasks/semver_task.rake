# frozen_string_literal: true

desc 'Semantically version and release, use `rake semver PART`, where PART is {major|minor|patch}'
task :semver do |_task, _args|
  gemspec = Dir.glob(File.expand_path(File.join(__dir__, '../../')) + '/*.gemspec').first
  version_file = Dir.glob(File.expand_path(File.join(__dir__, '../../')) + '/**/version.rb').first
  spec = Gem::Specification.load(gemspec)

  versions = spec.version.to_s.split('.').map(&:to_i)

  what = %w[ma mi pa].index(ARGV[1].to_s[0, 2].downcase)
  what ||= 2

  new_version = versions.tap { |parts| parts[what] += 1 }
  new_version = new_version.map.with_index { |v, i| i > what ? 0 : v }.join('.')

  version_file_content = File.read(version_file)
  File.open(version_file, 'w') do |file|
    file.puts version_file_content.gsub(/VERSION\s=\s'(.*)'/, "VERSION = '#{new_version}'")
  end

  puts "Updated version to #{new_version}"

  relative_version_path = Pathname.new(version_file).relative_path_from(Dir.pwd)

  `git commit #{relative_version_path} -m "Version #{new_version}"`
  `git push`
  `git tag #{new_version}`
  `git push --tags`
end
