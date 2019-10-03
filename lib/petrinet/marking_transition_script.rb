module Petrinet
  class MarkingTransitionScript
    def initialize(source)
      @source = source
    end

    def marking
      pairs = lines.select do |line|
        line =~ /:\d+\s*$/
      end.map do |line|
        parts = line.split(':')
        [parts[0].to_sym, parts[1].to_i]
      end
      Hash[pairs]
    end

    def transitions
      pairs = lines.reject do |line|
        line =~ /:\d+\s*$/
      end.map(&:to_sym)
    end

    private

    def lines
      @source.split(/\n/)
    end
  end
end

