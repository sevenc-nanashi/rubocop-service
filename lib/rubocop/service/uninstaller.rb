# frozen_string_literal: true

require "pathname"

module Rubocop
  module Service
    class Uninstaller
      def run
        puts "Reinstalling rubocop..."
        system "gem install rubocop -N"
        puts "Restored! Use `rubocop-service install` to reinstall rubocop-service."
      end
    end
  end
end
