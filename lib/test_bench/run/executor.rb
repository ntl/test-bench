module TestBench
  class Run
    module Executor
      AbstractMethodError = Class.new(RuntimeError)

      def self.included(cls)
        cls.class_exec do
          extend Build
          extend Configure
        end
      end

      def configure
      end

      def start
      end

      def execute(file)
        raise AbstractMethodError, "Subclass didn't implement execute (File: #{file.inspect})"
      end

      def finish
      end

      module Build
        def build
          instance = new
          instance.configure
          instance
        end
      end

      module Configure
        def configure(receiver, attr_name: nil)
          attr_name ||= :executor

          instance = build
          receiver.public_send(:"#{attr_name}=", instance)
        end
      end
    end
  end
end
