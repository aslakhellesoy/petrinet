require 'graphviz/dsl'

module Petrinet
  class SvgBuilder
    def initialize(net, transition_vector_by_transition_name, place_name_by_place_index, state_vector)
      @net = net
      @transition_vector_by_transition_name = transition_vector_by_transition_name
      @place_name_by_place_index = place_name_by_place_index
      @state_vector = state_vector
    end

    def svg
      raw_svg
    end

    private

    def raw_svg
      # Lexical scoping because the graphviz DSL changes the value of self
      net = @net
      transition_vector_by_transition_name = @transition_vector_by_transition_name
      place_name_by_place_index = @place_name_by_place_index
      state_vector = @state_vector

      tempfile = Tempfile.create('petrinet')
      digraph :PetriNet do
        graph[bgcolor: 'white', labeljust: 'l', labelloc: 't', nodesep: 0.5, penwidth: 0, ranksep: 0.5, style: 'filled']

        transition_vector_by_transition_name.each do |transition_name, transition_vector|
          transition_vector.each_with_index do |direction, place_index|
            place_name = place_name_by_place_index[place_index]
            raise "No place_name for index #{place_index}: #{place_name_by_place_index}" if place_name.nil?
            if direction < 0
              self.send("node_#{place_name}".to_sym) << self.send("node_#{transition_name}".to_sym)
            elsif direction > 0
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

        output :svg => tempfile.path # STDOUT
      end
      tempfile.read
    end
  end
end
