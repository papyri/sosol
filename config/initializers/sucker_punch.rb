# frozen_string_literal: true

require 'sucker_punch/async_syntax'

# SuckerPunch 2.x
SuckerPunch.exception_handler = ->(ex, _klass, _args) { Airbrake.notify(ex) }
# SuckerPunch 1.x
# SuckerPunch.exception_handler { |ex| Airbrake.notify(ex) }
