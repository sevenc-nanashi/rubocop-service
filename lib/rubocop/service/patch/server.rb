# frozen_string_literal: true

module RuboCop
  module Server
    class << self
      def support_server?
        # RUBY_ENGINE == 'ruby' && !RuboCop::Platform.windows?
        RUBY_ENGINE == "ruby"
      end
    end
  end
end
