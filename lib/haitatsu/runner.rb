module Haitatsu
  class Runner
    class ExecutionError < Exception; end

    def run(method, output)
      say(output)

      fork do
        begin
          print "\n\n" if $VERBOSE
          send(method)
          print "\n" if $VERBOSE
        rescue ExecutionError => e
          handle_error(e)
        end
      end

      pid, status = Process.wait2
      exit 1 if status != 0

      unless $VERBOSE
        # while true
        #   print "."
        #   sleep(0.5)
        # end
      end
    end

    def handle_error(exception)
      print "\n\n"
      say("<%= color('An error occurred', BOLD, RED) %>")
      print "\n"
      say(exception.message)
      exit 1
    end

    def remote_host_and_user
      $CONFIG["remote"].split("@").reverse
    end

    def run_ssh(command, server)
      Net::SSH.start(server["host"], $CONFIG["user"]) do |ssh|
        # ssh.exec(command) do |ch, stream, data|
        #   if stream == :stderr
        #     raise ExecutionError.new("Error for server #{server["host"]}\n#{data}")
        #   end
        # end

        channel = ssh.open_channel do |ch, success|
          ch.request_pty do |ch, success|
            unless success
              raise ExecutionError.new("Could not obtain pty")
            end
          end

          ch.exec(command) do |ch2, success|
            ch2.on_data do |c, data|
              $stdout.print(data) if $VERBOSE
            end

            ch.on_extended_data do |c, type, data|
              raise ExecutionError.new("Error for server #{server["host"]}\n#{data}")
            end
          end
        end

        channel.wait
      end
    end

    def check
      `git remote add #{$CONFIG["app"]} #{$CONFIG["remote"]}:#{$CONFIG["location"]} 2>&1 /dev/null`

      $CONFIG["servers"].each do |name, attributes|
        command = <<-EOF
          set -e
          if [ ! -d #{$CONFIG["location"]} ]; then
            mkdir #{$CONFIG["location"]}
            cd #{$CONFIG["location"]}
            git config receive.denyCurrentBranch ignore
          fi
        EOF

        run_ssh(command, attributes)
      end
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
      $CONFIG["servers"].each do |name, attributes|
        command = <<-EOF
          set -e
          . .profile
          cd #{$CONFIG["location"]}
          git reset --hard master
          bundle install --deployment --without development test
        EOF

        run_ssh(command, attributes)
      end
    end

    def launch
      $CONFIG["servers"].each do |name, attributes|
        attributes["tasks"].each { |t| run_ssh(t, attributes) } if attributes["tasks"]
        run_ssh("sudo sv restart #{$CONFIG["app"]}", attributes)
      end
    end
  end
end
