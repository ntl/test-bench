module TestBench
  class Run
    module Output
      def self.included(cls)
        cls.class_exec do
          include Fixture::Telemetry::Sink::Handler
          include Events

          extend Build
          extend RegisterTelemetry
        end
      end

      def writer
        @writer ||= Fixture::Writer::Substitute.build
      end
      attr_writer :writer

      def configure(writer: nil)
      end

      module Build
        def build(writer: nil)
          instance = new

          Fixture::Writer.configure(instance, writer:)

          writer = instance.writer
          instance.configure(writer:)

          instance
        end
      end

      module RegisterTelemetry
        def register_telemetry(telemetry, writer: nil)
          instance = build(writer:)

          telemetry.register(instance)
          instance
        end
        alias :register :register_telemetry
      end
    end
  end
end
