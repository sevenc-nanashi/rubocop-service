# frozen_string_literal: true

module RuboCop
  module Server
    class Cache
      class << self
        def project_dir_cache_key
          # @project_dir_cache_key ||= project_dir[1..].tr('/', '+')
          @project_dir_cache_key ||= project_dir.tr("/:", "++")
        end
      end
    end
  end
end
