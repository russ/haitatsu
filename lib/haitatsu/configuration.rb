module Haitatsu
  class Configuration
    include Execute

    def values
      values = []
      execute("cd #{$CONFIG["location"]} && cat .env", $CONFIG["servers"]) do |output|
        values += output.map { |l| l.split("=") }
      end

      values.uniq
    end

    def write(configuration)
      command = "cd #{$CONFIG["location"]}\n"
      command << "echo '' > .env\n"
      configuration.uniq.each do |line|
        command << "\necho '#{line[0]}=#{line[1]}' >> .env"
      end

      execute(command, $CONFIG["servers"])
    end
  end
end
