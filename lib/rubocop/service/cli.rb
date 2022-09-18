# frozen_string_literal: true

require "optparse"

module RuboCop
  module Service
    class CLI
      def initialize
        @options = { verbose: false }
        @commands = {}
      end

      def run(argv)
        parser = OptionParser.new

        parser.program_name = "rubocop-service"
        parser.version = VERSION

        command "install", "Patch the rubocop." do
          RuboCop::Service::Installer.new.run
        end
        command "uninstall", "Unpatch the rubocop." do
          RuboCop::Service::Uninstaller.new.run
        end
        command "start", "Start the manager server." do
          RuboCop::Service::Server.start
        end
        command "stop", "Stop the manager server." do
          RuboCop::Service::Server.stop
        end
        command "status", "Show status of the manager server." do
          RuboCop::Service::Server.status
        end
        command nil do
          puts parser.help
        end

        parser.banner = +<<~BANNER
          Usage: rubocop-service [options] [command]

          Commands:
        BANNER
        @commands.each do |command, (desc, _block)|
          next unless desc
          parser.banner << "    #{command} - #{desc}\n"
        end

        parser.separator ""
        parser.separator "Options:"
        parser.on("-v", "--verbose", "Verbose output") do |verb|
          @options[:verbose] = verb
        end

        parser.parse! argv

        ENV["RUBOCOP_SERVICE_VERBOSE"] = "true" if @options[:verbose]

        if @commands[argv.first]
          @commands[argv.first].last.call
        else
          @commands[nil].last.call
        end
      end

      def command(name, description = nil, &block)
        @commands[name] = [description, block]
      end
    end
  end
end
