module Haitatsu
  class Runner
    include Execute

    class ExecutionError < Exception; end

    def run(method, output)
      say(output)

      fork do
        begin
          print "\n\n" if $VERBOSE
          send(method)
          print "\n"
        rescue ExecutionError => e
          handle_error(e)
        end
      end

      pid, status = Process.wait2
      exit 1 if status != 0
    end

    def handle_error(exception)
      print "\n\n"
      say("<%= color('An error occurred', BOLD, RED) %>")
      print "\n"
      say(exception.message)
      exit 1
    end

    def check
      `git remote add #{$CONFIG["app"]} #{$CONFIG["remote"]}:#{$CONFIG["location"]} 2>&1 /dev/null`

      command = <<-EOF
        set -e
        if [ ! -d #{$CONFIG["location"]} ]; then
          mkdir #{$CONFIG["location"]}
          cd #{$CONFIG["location"]}
          git config receive.denyCurrentBranch ignore
        fi
      EOF

      execute(command, $CONFIG["servers"])
    end

    def check_for_updates
      return if $FORCE

      local_revision = `git rev-parse HEAD`.strip
      remote_revision = `git ls-remote #{$CONFIG["repo"]} | awk '{ print $1 }' | head -n 1`.strip

      if local_revision == remote_revision
        say("\n\n<%= color('LATEST DEPLOYED', BOLD) %>")
        exit 1
      end
    end

    def push
      Open3.popen3("git push #{$CONFIG["repo"]}") do |stdin, stdout, stderr|
        unless $? == 0
          raise ExecutionError.new(stderr.read)
        end
      end
    end

    def setup
      command = <<-EOF
        set -e
        . .profile
        cd #{$CONFIG["location"]}
        git reset --hard master
        bundle install --deployment --without development test
      EOF

      execute(command, $CONFIG["servers"])
    end

    def launch
      $CONFIG["servers"].each do |name, attributes|
        fork do
          if attributes["tasks"]
            attributes["tasks"].each do |t|
              execute(t, [[ name, attributes ]])
            end
          end
        end
      end

      Process.waitall

      execute("sudo sv restart #{$CONFIG["app"]}", $CONFIG["servers"])
    end
  end
end
