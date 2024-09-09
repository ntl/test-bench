module TestBench
  class Run
    module Events
      include Fixture

      FileStarted = Telemetry::Event.define(:file)
      FileFinished = Telemetry::Event.define(:file, :result)
      FileTerminated = Telemetry::Event.define(:file, :error_message, :error_text)

      Started = Telemetry::Event.define(:random_seed)
      Finished = Telemetry::Event.define(:random_seed, :result)
    end
  end
end
