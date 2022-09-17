# frozen_string_literal: true

require_relative "service/version"
require_relative "service/utils"

module Rubocop
  module Service
    class Error < StandardError
    end

    autoload :CLI, "rubocop/service/cli"
    autoload :Installer, "rubocop/service/installer"
    autoload :Uninstaller, "rubocop/service/uninstaller"
  end
end
