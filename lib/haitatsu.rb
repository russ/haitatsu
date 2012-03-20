require "commander/import"
require "grit"
require "yaml"
require "net/ssh"
require "open3"

require "haitatsu/version"
require "haitatsu/runner"

program(:name, "Haitatsu")
program(:version, "0.0.1")
program(:description, "Push oriented deployment.")

default_command(:deploy)

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
