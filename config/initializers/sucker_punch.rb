SuckerPunch.exception_handler = -> (ex, klass, args) { Airbrake.notify(ex) }
