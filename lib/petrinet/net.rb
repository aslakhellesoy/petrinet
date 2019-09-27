require_relative 'pnml_builder'
require 'graphviz/dsl'

module Petrinet
  # Represents a Petri Net in a particular state. Instances of this class are immutable. The following methods return
  # new instances:
  #
  # * mark
  # * fire
  #
  # The internal representation uses a VASS - https://en.wikipedia.org/wiki/Vector_addition_system
  # A good explanation of how this works with Petri Nets is here: https://github.com/bitwrap/bitwrap-io/blob/master/whitepaper.md
  #
  class Net
    def self.from_pnml(xml)
      builder = PnmlBuilder.new(xml)
      builder.net
    end

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

    # Marks the petri net and returns a new instance
    def mark(markings)
      new_state_vector = @state_vector.dup
      markings.each do |place_name, token_count|
        index = @place_index_by_place_name[place_name]
        new_state_vector[index] = token_count
      end
      self.class.new(new_state_vector, @place_index_by_place_name, @transition_vector_by_transition_name)
    end

    def fire(transition_name)
      new_state_vector = new_state_vector(transition_name)
      raise "Cannot fire: #{transition_name}" unless valid?(new_state_vector)
      self.class.new(new_state_vector, @place_index_by_place_name, @transition_vector_by_transition_name)
    end

    def fireable?(transition_name)
      !new_state_vector(transition_name).any? { |s| s.negative? }
    end

    def valid?(state_vector)
      !(state_vector.any? { |s| s.negative? })
    end

    def new_state_vector(transition_name)
      transition_vector = @transition_vector_by_transition_name[transition_name]
      raise "Unknown transition: #{transition_name}. Known transitions: #{@transition_vector_by_transition_name.keys}" if transition_vector.nil?
      @state_vector.zip(transition_vector).map { |s, t| s + t }
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

    def to_svg
      # Lexical scoping because the graphviz DSL changes the value of self
      net = self
      transition_vector_by_transition_name = @transition_vector_by_transition_name
      place_name_by_place_index = @place_index_by_place_name.invert
      state_vector = @state_vector

      tempfile = Tempfile.create('petrinet')
      digraph :PetriNet do
        graph[bgcolor: 'white', labeljust: 'l', labelloc: 't', nodesep: 0.5, penwidth: 0, ranksep: 0.5, style: 'filled']

        transition_vector_by_transition_name.each do |transition_name, transition_vector|
          # puts "#{transition_name} -> #{transition_vector}"
          transition_vector.each_with_index do |direction, place_index|
            place_name = place_name_by_place_index[place_index]
            raise "No place_name for index #{place_index}: #{place_name_by_place_index}" if place_name.nil?
            if direction < 0
              # puts "#{place_name} -> #{transition_name}"
              self.send("node_#{place_name}".to_sym) << self.send("node_#{transition_name}".to_sym)
            elsif direction > 0
              # puts "#{transition_name} -> #{place_name}"
              self.send("node_#{transition_name}".to_sym) << self.send("node_#{place_name}".to_sym)
            end
          end

          subgraph "cluster_transition_#{transition_name}" do
            graph[label: transition_name, labeljust: 'l', labelloc: 'c']
            fillcolor = net.fireable?(transition_name) ? 'black' : 'red'
            node[shape: 'box', fillcolor: fillcolor, style: "solid, filled", height: 0.1, width: 0.5]
            self.send("node_#{transition_name}".to_sym)[label: '', height: 0.1, width: 0.5]
          end
        end

        place_name_by_place_index.each do |place_index, place_name|
          marking = state_vector[place_index]
          subgraph "cluster_place_#{place_name}" do
            graph[label: place_name]
            node[shape: 'circle']
            self.send("node_#{place_name}".to_sym)[label: marking]
          end
        end

        output :dot => tempfile.path # STDOUT
      end
      tempfile.read
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
    end
  end
end
