# SuckerPunch 2.x
# SuckerPunch.exception_handler = ->(ex, klass, args) { Airbrake.notify(ex) }
# SuckerPunch 1.x
SuckerPunch.exception_handler { |ex| Airbrake.notify(ex) }
