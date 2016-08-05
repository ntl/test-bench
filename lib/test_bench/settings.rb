module TestBench
  class Settings
    attr_writer :abort_on_error
    attr_writer :exclude_pattern
    attr_writer :writer
    attr_writer :record_telemetry
    attr_writer :reverse_backtraces
    attr_reader :line_number

    def abort_on_error
      nil_coalesce :@abort_on_error, Defaults.abort_on_error
    end

    def color
      writer.color
    end

    def color= value
      writer.color = value
    end

    def exclude_pattern
      nil_coalesce :@exclude_pattern, Defaults.exclude_pattern
    end

    def lower_verbosity
      writer.lower_verbosity
    end

    def nil_coalesce ivar, default_value
      if instance_variable_defined? ivar
        instance_variable_get ivar
      else
        instance_variable_set ivar, default_value
      end
    end

    def raise_verbosity
      writer.raise_verbosity
    end

    def record_telemetry
      nil_coalesce :@record_telemetry, Defaults.record_telemetry
    end

    def reverse_backtraces
      nil_coalesce :@reverse_backtraces, Defaults.reverse_backtraces
    end

    def writer
      @writer ||= Output::Writer.new
    end

    def line_number= value
      value = value.to_i
      if value > 0
        @line_number = value 
      else
        @line_number = nil
      end
    end

    def self.toplevel
      Registry.get TOPLEVEL_BINDING
    end
  end
end
