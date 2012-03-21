module Haitatsu
  module Execute
    def execute(command, servers = [])
      Net::SSH::Multi.start do |session|
        servers.each do |name, attributes|
          session.use("#{$CONFIG["user"]}@#{attributes["host"]}")
        end

        channel = session.open_channel do |ch, success|
          ch.request_pty do |ch, success|
            unless success
              raise ExecutionError.new("Could not obtain pty")
            end
          end

          ch.exec(command) do |ch2, success|
            ch2.on_data do |c, data|
              yield data.strip.split("\r\n") if block_given?
              $stdout.print(data) if $VERBOSE
            end

            ch.on_extended_data do |c, type, data|
              raise ExecutionError.new("Error for server #{server["name"]}\n#{data}")
            end
          end
        end

        channel.wait
        session.loop
      end
    end
  end
end
