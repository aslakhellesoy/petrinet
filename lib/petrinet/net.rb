module Petrinet
  class Net
    def self.build(&proc)
      builder = Builder.new
      builder.instance_exec(&proc)
      builder.net
    end

    def initialize(transitions)
      @transitions = transitions
    end

    def fire(transition_name)
      transition = @transitions[transition_name.to_sym]
      raise "No such transition: #{transition_name}" unless transition
      transition.fire
    end

    class Transition
      def initialize(name, takes, gives)
        @name, @takes, @gives = name, takes, gives
      end

      def fire
        check
        @takes.each do |place|
          place.tokens -= 1
        end
        @gives.each do |place|
          place.tokens += 1
        end
      end

      private

      def check
        @takes.each do |place|
          if place.tokens < 1
            raise "Cannot fire: #{@name}"
          end
        end
      end
    end

    class Place
      attr_accessor :tokens

      def initialize
        @tokens = 0
      end
    end

    class Builder
      def initialize
        @place_by_name = Hash.new {|h,k| h[k] = Place.new}
        @transitions = Hash.new
      end

      def transition(transition_name, arcs)
        takes = [arcs[:take]].flatten.map do |place_name|
          @place_by_name[place_name]
        end
        gives = [arcs[:give]].flatten.map do |place_name|
          @place_by_name[place_name]
        end

        @transitions[transition_name] = Transition.new(transition_name, takes, gives)
      end

      def token(place_name, count)
        @place_by_name[place_name].tokens = count
      end

      def net
        Net.new(@transitions)
      end
    end
  end
end
