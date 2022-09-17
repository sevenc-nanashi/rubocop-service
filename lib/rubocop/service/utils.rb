# frozen_string_literal: true

def dputs(*strings)
  puts strings.join(" ") if ENV["RUBOCOP_SERVICE_VERBOSE"] == "true"
end
