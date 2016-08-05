module TestBench
  module Structure
    def assert subject=nil, mod=nil, assert_class: nil, caller_location: nil, &block
      assert_class ||= Assert
      caller_location ||= caller_locations[0]

      telemetry = Telemetry::Registry.get binding

      unless assert_class.(subject, mod, &block)
        raise Assert::Failed.build caller_location
      end

    ensure
      telemetry.asserted
    end

    def context prose=nil, suppress_exit: nil, &block
      suppress_exit ||= false

      telemetry = Telemetry::Registry.get binding
      settings = Settings::Registry.get binding

      unless prose.nil? or prose.is_a? String
        raise TypeError, "Prose must be a String"
      end

      begin
        telemetry.context_entered prose
        block.() if block

      rescue => error
        Structure.error error, binding

      ensure
        @test_instance = nil
        nesting = telemetry.context_exited prose

        if nesting.zero? and telemetry.failed?
          exit 1 unless suppress_exit
        end
      end
    end

    def refute *arguments, &block
      assert *arguments, :assert_class => Assert::Refute, :caller_location => caller_locations[0], &block
    end

    def test prose=nil, &block
      telemetry = Telemetry::Registry.get binding
      settings = Settings::Registry.get binding
      line_number = settings.line_number
      require 'pry'
      return if line_number && line_number != block.source_location[1]

      prose ||= 'Test'

      unless prose.is_a? String
        raise TypeError, "Prose must be a String"
      end

      if block.nil?
        telemetry.test_skipped prose
        return
      end

      begin
        telemetry.test_started prose
        block.()
        telemetry.test_passed prose

      rescue => error
        telemetry.test_failed prose
        Structure.error error, binding

      ensure
        telemetry.test_finished prose
      end
    end

    def self.error error, binding
      telemetry = Telemetry::Registry.get binding
      settings = Settings::Registry.get binding

      telemetry.error_raised error

      exit 1 if settings.abort_on_error
    end
  end
end
