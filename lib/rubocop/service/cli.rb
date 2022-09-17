# frozen_string_literal: true

require "optparse"

module RuboCop
  module Service
    class CLI
      def initialize
        @options = { verbose: false }
      end

      def run(argv)
        parser = OptionParser.new
        parser.on("-v", "--verbose", "Verbose output") do |verb|
          @options[:verbose] = verb
        end

        parser.parse! argv

        ENV["RUBOCOP_SERVICE_VERBOSE"] = "true" if @options[:verbose]

        case argv[0]
        when "install"
          RuboCop::Service::Installer.new.run
        when "uninstall"
          RuboCop::Service::Uninstaller.new.run
        when "start"
          RuboCop::Service::Server.start
        when nil
          puts parser.help
        else
          abort
        end
      end
    end
  end
end
