reporter = Metriks::LibratoMetricsReporter.new(ENV['LIBRATO_USER'],ENV['LIBRATO_TOKEN'])
reporter.start
