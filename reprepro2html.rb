#!/usr/bin/ruby

require 'json'
require 'optparse'
require 'builder'

options = {}

options[:reprepro_basepath] = ''
options[:reprepro_conf_distributions] = ''

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-p", "--path [DIRECTORY]", "path to reprepro repo" ) do |p|
    options[:reprepro_basepath] = p
    options[:reprepro_conf_distributions] = File.join(options[:reprepro_basepath], 'conf/distributions')
  end
end.parse!

if ! File.directory?(options[:reprepro_basepath])
  $stderr.puts "Could not access reprepro path"
  exit 1
end

if ! File.readable?(options[:reprepro_conf_distributions])
  $stderr.puts "Could not read #{options[:reprepro_conf_distributions]}"
  exit 1
end

repository = {}
repository[:distributions_available] = []
repository[:packages] = {}
File.readlines(options[:reprepro_conf_distributions]).each do |line|
  next if line !~ /\ASuite: (.*)/
  repository[:distributions_available] << $1
end


repository[:distributions_available].each do |dist|
  output = %x{cd #{options[:reprepro_basepath]} && reprepro --list-format='\${\$codename},\${\$component},\${\$architecture},\${package},\${version}\n' list #{dist}}
  output.each_line do |line|
    codename,component,architecture,package,version = line.chomp.split(/,/)
    repository[:packages][package] = {} if !repository[:packages][package]
    repository[:packages][package][dist] = {} if !repository[:packages][package][dist]

    repository[:packages][package][dist][architecture] = {
      'version' => version
    }
  end
end


def packages2html(packages, distributions )
  html = Builder::XmlMarkup.new
  html.table {
    html.tr {
    html.th('Package')
    distributions.each{|h| html.th(h)}
    }
    packages.each_pair.each do |packagename, entry|
      html.tr {
        html.td(packagename)
        distributions.each do |dist|
          if entry[dist]
            info = entry[dist].map { |k,v| "#{k}: #{v['version']}" }.join(",")
            html.td("#{info}")
          else
            html.td("-")
          end
        end
      }
    end
  }
  return html
end



puts packages2html(repository[:packages], repository[:distributions_available]).join()
