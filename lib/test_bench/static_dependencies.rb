
# test_bench/pseudorandom/defaults
module TestBench
  module Pseudorandom
    module Defaults
      def self.seed
        ENV.fetch('SEED') do
          @seed ||= ::Random.new_seed.to_s(36)
        end
      end
    end
  end
end

# test_bench/pseudorandom/iterator
module TestBench
  module Pseudorandom
    class Iterator
      attr_accessor :seed
      attr_accessor :namespace

      def iterations
        @iterations ||= 0
      end
      attr_writer :iterations

      attr_reader :random

      def initialize(random)
        @random = random
      end

      def self.build(seed, namespace=nil)
        random = self.random(seed, namespace)

        instance = new(random)
        instance.seed = seed
        instance.namespace = namespace
        instance
      end

      def self.random(seed, namespace)
        random_seed = seed.to_i(36)

        if not namespace.nil?
          namespace_hash = namespace_hash(namespace)
          random_seed ^= namespace_hash
        end

        ::Random.new(random_seed)
      end

      def self.namespace_hash(namespace)
        namespace_digest = Digest::Hash.digest(namespace)

        namespace_digest.unpack1('Q>')
      end

      def next
        self.iterations += 1

        random.bytes(8)
      end

      def namespace?(namespace)
        source?(self.seed, namespace)
      end

      def seed?(seed)
        source?(seed, self.namespace)
      end

      def iterated?
        iterations > 0
      end

      def source?(seed, namespace=nil)
        control_random = ::Random.new(random.seed)
        compare_random = Iterator.random(seed, namespace)

        control_value = control_random.rand
        compare_value = compare_random.rand

        control_value == compare_value
      end
    end
  end
end

# test_bench/pseudorandom/generator
module TestBench
  module Pseudorandom
    class Generator
      def iterator
        @iterator ||= Iterator.build(seed)
      end
      attr_writer :iterator

      attr_accessor :seed
      alias :set_seed :seed=

      def initialize(seed)
        @seed = seed
      end

      def self.build(seed=nil)
        seed ||= Defaults.seed

        new(seed)
      end

      def self.instance
        @instance ||= build
      end

      def self.configure(receiver, attr_name: nil)
        attr_name ||= :random_generator

        instance = self.instance
        receiver.public_send(:"#{attr_name}=", instance)
      end

      def string
        self.integer.to_s(36)
      end

      def boolean
        self.integer % 2 == 1
      end

      def integer
        iterator.next.unpack1('Q>')
      end

      def decimal
        iterator.next.unpack1('D')
      end

      def reset(namespace=nil)
        self.iterator = Iterator.build(seed, namespace)
      end

      def reset?(namespace=nil)
        if iterator.iterated?
          false
        elsif namespace.nil?
          true
        else
          iterator.namespace?(namespace)
        end
      end

      def namespace?(namespace)
        iterator.namespace?(namespace)
      end
    end
  end
end

# test_bench/pseudorandom/pseudorandom
module TestBench
  module Pseudorandom
    extend self

    def reset
      Generator.instance.reset
    end

    def string
      Generator.instance.string
    end

    def boolean
      Generator.instance.boolean
    end

    def integer
      Generator.instance.integer
    end

    def decimal
      Generator.instance.decimal
    end
  end
end
