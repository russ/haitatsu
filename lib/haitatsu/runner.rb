module Haitatsu
  class Runner
    include Execute

    class ExecutionError < Exception; end

    def run(method, output, server)
      say(output)

      fork do
        begin
          print "\n\n" if $VERBOSE
          send(method, server)
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

    def check(server)
      `git remote add #{$CONFIG["app"]} #{$CONFIG["remote"]}:#{$CONFIG["location"]} 2>&1 /dev/null`

      command = <<-EOF
        set -e
        if [ ! -d #{$CONFIG["location"]} ]; then
          mkdir #{$CONFIG["location"]}
          cd #{$CONFIG["location"]}
          git config receive.denyCurrentBranch ignore
        fi
      EOF

      execute(command, server)
    end

    def check_for_updates(server)
      return if $FORCE

      local_revision = `git rev-parse HEAD`.strip
      remote_revision = `git ls-remote #{$CONFIG["repo"]} | awk '{ print $1 }' | head -n 1`.strip

      if local_revision == remote_revision
        say("\n\n<%= color('LATEST DEPLOYED', BOLD) %>")
        exit 1
      end
    end

    def push(server)
      Open3.popen3("git push #{$CONFIG["repo"]}") do |stdin, stdout, stderr|
        unless $? == 0
          raise ExecutionError.new(stderr.read)
        end
      end
    end

    def setup(server)
      command = <<-EOF
        set -e
        . .profile
        cd #{$CONFIG["location"]}
        git reset --hard master
        bundle install --deployment --without development test
      EOF

      execute(command, server)
    end

    def launch(server)
      server["tasks"].each { |t| execute(t, server) } if server["tasks"]
      execute("sudo sv restart #{$CONFIG["app"]}", server)
    end
  end
end
