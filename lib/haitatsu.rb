require "commander/import"
require "grit"
require "yaml"
require "net/ssh"
require "net/ssh/multi"
require "open3"
require "progress_bar"

require "haitatsu/version"
require "haitatsu/execute"
require "haitatsu/configuration"
require "haitatsu/runner"

program(:name, "Haitatsu")
program(:version, "0.0.1")
program(:description, "Push oriented deployment.")

default_command(:help)

global_option("-c", "--config FILE", "Configuration file.")
global_option("-f", "--force", "Force a deployment.")
global_option("-V", "--verbose", "Be verbose.")

command(:deploy) do |c|
  c.syntax = "haitatsu deploy"
  c.description = "Deploys the application"
  c.action do |args, options|
    runner = Haitatsu::Runner.new

    $CONFIG = YAML::load(File.read(options.config || ".haitatsu"))
    $FORCE = options.force
    $VERBOSE = options.verbose

    runner.run(:check, "Checking repository ")
    runner.run(:check_for_updates, "Checking for updates ")
    runner.run(:push, "Pushing new commits ")
    runner.run(:setup, "Setting up app ")
    runner.run(:launch, "Launching app ")

    say("\n<%= color('DONE', BOLD) %>\n")
  end
end

command(:config) do |c|
  c.syntax = "haitatsu config"
  c.description = "show application configuration values"
  c.action do |args, options|
    configuration = Haitatsu::Configuration.new

    $CONFIG = YAML::load(File.read(options.config || ".haitatsu"))
    $VERBOSE = options.verbose

    configuration.values.each do |config|
      say("<%= color('#{config[0]}', BOLD) %> => #{config[1]}")
    end
  end
end

command("config:add") do |c|
  c.syntax = "haitatsu config:add KEY1=VALUE1 ..."
  c.description = "add one more config vars"
  c.action do |args, options|
    configuration = Haitatsu::Configuration.new

    $CONFIG = YAML::load(File.read(options.config || ".haitatsu"))
    $VERBOSE = options.verbose

    config = configuration.values
    args.each do |a|
      k,v = a.split("=")
      config << [ k.upcase, v ]
    end

    configuration.write(config)
  end
end

command("config:remove") do |c|
  c.syntax = "haitatsu config:remove KEY1 [KEY2 ...]"
  c.description = "remove one more config vars"
  c.action do |args, options|
    configuration = Haitatsu::Configuration.new

    $CONFIG = YAML::load(File.read(options.config || ".haitatsu"))
    $VERBOSE = options.verbose

    config = configuration.values
    config.delete_if do |line|
      args.map(&:downcase).include?(line[0].downcase)
    end

    configuration.write(config)
  end
end
