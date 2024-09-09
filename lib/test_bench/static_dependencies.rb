
# digest/hash/irrational_number
module Digest
  class Hash
    module IrrationalNumber
      PI = Rational(
        0xFFFF_FFFF_FFFF_FFFF,
        0x517C_C1B7_2722_0A95
      )

      def self.get
        PI
      end

      def self.numerator
        PI.numerator
      end

      def self.denominator
        PI.denominator
      end
    end
  end
end

# digest/hash/hash
module Digest
  class Hash
    def buffer
      @buffer ||= String.new(
        encoding: 'BINARY',
        capacity: self.class.digest_size_bytes
      )
    end

    def hash
      @hash ||= 0
    end
    attr_writer :hash

    def previous_hash
      @previous_hash ||= 0
    end
    attr_writer :previous_hash

    def self.digest(text)
      instance = new
      instance.update(text)
      instance.digest
    end

    def self.hexdigest(text)
      instance = new
      instance.update(text)
      instance.hexdigest
    end

    def self.file(path)
      instance = new

      File.open(path, 'r') do |io|
        until io.eof?
          text = io.read
          instance.update(text)
        end
      end

      instance
    end

    def update(text)
      byte_offset = 0

      bitmask = IrrationalNumber.numerator

      irrational_denominator = IrrationalNumber.denominator

      digest_size_bytes = self.class.digest_size_bytes

      until byte_offset == text.bytesize
        bytes_remaining = digest_size_bytes - buffer.bytesize

        slice = text.byteslice(byte_offset, bytes_remaining)
        slice.force_encoding('BINARY')

        buffer << slice

        buffer_hash = 0

        buffer.unpack('C*') do |byte|
          buffer_hash <<= 8

          buffer_hash += byte
        end

        buffer_hash += irrational_denominator
        buffer_hash += previous_hash << 6
        buffer_hash += previous_hash >> 2

        next_hash = previous_hash ^ buffer_hash
        next_hash &= bitmask

        self.hash = next_hash

        if buffer.bytesize == digest_size_bytes
          self.previous_hash = next_hash

          buffer.clear
        end

        byte_offset += slice.bytesize
      end

      hash
    end
    alias :<< :update

    def text?(text)
      digest = self.class.digest(text)

      digest == self.digest
    end

    def digest
      [hash].pack('Q>')
    end

    def hexdigest
      '%016X' % hash
    end

    def clone
      cloned_digest = self.class.new
      cloned_digest.hash = hash
      cloned_digest.previous_hash = previous_hash
      cloned_digest.buffer << buffer
      cloned_digest
    end

    def self.digest_size_bytes
      digest_size_bits / 8
    end

    def self.digest_size_bits
      64
    end
  end
end

# pseudorandom/defaults
module Pseudorandom
  module Defaults
    def self.seed
      ENV.fetch('SEED') do
        @seed ||= ::Random.new_seed.to_s(36)
      end
    end
  end
end

# pseudorandom/iterator
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

# pseudorandom/generator
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

# pseudorandom/pseudorandom
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
