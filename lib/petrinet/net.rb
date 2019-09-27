module Petrinet
  # Represents a Petri Net in a particular state.
  #
  # The internal representation uses a VASS - https://en.wikipedia.org/wiki/Vector_addition_system
  # A good explanation of how this works with Petri Nets is here: https://github.com/bitwrap/bitwrap-io/blob/master/whitepaper.md
  #
  class Net
    def self.build(&proc)
      builder = Builder.new
      builder.instance_exec(&proc)
      builder.net
    end

    def initialize(state_vector, place_index_by_place_name, transition_vector_by_transition_name)
      @state_vector = state_vector
      @place_index_by_place_name = place_index_by_place_name
      @transition_vector_by_transition_name = transition_vector_by_transition_name
      freeze
    end

    def mark(marking)
      new_state_vector = @state_vector.dup
      marking.each do |place_name, token_count|
        index = @place_index_by_place_name[place_name]
        new_state_vector[index] = token_count
      end
      self.class.new(new_state_vector, @place_index_by_place_name, @transition_vector_by_transition_name)
    end

    def fire(transition_name)
      transition_vector = @transition_vector_by_transition_name[transition_name]
      new_state_vector = @state_vector.zip(transition_vector).map { |s,t| s + t }
      invalid = new_state_vector.any? {|s| s.negative?}
      raise "Cannot fire: #{transition_name}" if invalid
      self.class.new(new_state_vector, @place_index_by_place_name, @transition_vector_by_transition_name)
    end

    def fireable
      result = Set.new
      @transition_vector_by_transition_name.keys.each do |transition_name|
        begin
          fire(transition_name)
          result.add(transition_name)
        rescue => ignore
          # It wasn't fireable - ignore it
        end
      end
      result
    end

    class Builder
      def initialize
        @place_names = Set.new
        @transition_by_name = Hash.new
        @state_vector = []
      end

      def transition(transition_name, arcs)
        take_place_names = [arcs[:take]].flatten
        give_place_names = [arcs[:give]].flatten
        @place_names.merge(take_place_names)
        @place_names.merge(give_place_names)
        @transition_by_name[transition_name] = Transition.new(take_place_names, give_place_names)
      end

      def net
        place_index_by_place_name = Hash.new do |h, k|
          index = h.size
          @state_vector[index] = 0
          h[k] = index
        end

        transition_vector_by_transition_name_pairs = @transition_by_name.map do |transition_name, transition|
          [transition_name, transition.to_vector(@place_names.size, place_index_by_place_name)]
        end
        transition_vector_by_transition_name = Hash[transition_vector_by_transition_name_pairs]

        Net.new(@state_vector.freeze, place_index_by_place_name.freeze, transition_vector_by_transition_name.freeze)
      end

      class Transition
        def initialize(take_place_names, give_place_names)
          @take_place_names = take_place_names
          @give_place_names = give_place_names
        end

        def to_vector(size, place_index_by_place_name)
          transition_vector = Array.new(size, 0)
          @take_place_names.each do |take_place_name|
            index = place_index_by_place_name[take_place_name]
            transition_vector[index] -= 1
          end
          @give_place_names.each do |give_place_name|
            index = place_index_by_place_name[give_place_name]
            transition_vector[index] += 1
          end
          transition_vector
        end
      end

      class Place
        attr_accessor :tokens

        def initialize
          @tokens = 0
        end
      end
    end
  end
end
