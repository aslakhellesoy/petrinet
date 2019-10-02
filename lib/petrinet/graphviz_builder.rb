require 'tempfile'
require 'nokogiri'
require 'graphviz/dsl'

module Petrinet
  class GraphvizBuilder
    def initialize(net, transition_vector_by_transition_name, place_name_by_place_index, state_vector)
      @net = net
      @transition_vectors_by_transition_name = transition_vector_by_transition_name
      @place_name_by_place_index = place_name_by_place_index
      @state_vector = state_vector
    end

    def svg
      dot_source = dot
      dotfile = Tempfile.new('petrinet.dot')
      dotfile.write(dot_source)
      dotfile.close
      svgfile = Tempfile.new('petrinet.svg')
      # circo dot fdp neato nop nop1 nop2 osage patchwork sfdp twopi
      `dot -T svg -Kdot #{dotfile.path} -o #{svgfile.path}`
      `cat #{svgfile.path}`
      svg = svgfile.read
      processed_svg(svg)
    end

    private

    def processed_svg(svg)
      doc = Nokogiri::XML(svg)
      doc = draw_tokens(doc)
      doc = remove_rectangles(doc)
      doc.to_xml
    end

    def dot
      # Lexical scoping because the graphviz DSL changes the value of self
      net = @net
      transition_vectors_by_transition_name = Hash[@transition_vectors_by_transition_name.sort]
      place_name_by_place_index = Hash[@place_name_by_place_index.sort]
      state_vector = @state_vector

      tempfile = Tempfile.create('petrinet')
      digraph :PetriNet do
        graph[bgcolor: 'white', labeljust: 'l', labelloc: 't', nodesep: 0.5, penwidth: 0, ranksep: 0.5, style: 'filled']

        transition_vectors_by_transition_name.each do |transition_name, transition_vectors|
          transition_vectors.each do |transition_vector|
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
              fillcolor = net.fireable?(transition_name) ? 'red' : 'black'
              node[shape: 'box', fillcolor: fillcolor, style: "solid, filled", height: 0.1, width: 0.5]
              self.send("node_#{transition_name}".to_sym)[label: '', height: 0.1, width: 0.5]
            end
          end
        end

        place_name_by_place_index.each do |place_index, place_name|
          marking = state_vector[place_index]
          subgraph "cluster_place_#{place_name}" do
            label = place_name
            graph[label: label]
            node[shape: 'circle']
            self.send("node_#{place_name}".to_sym)[label: marking]
          end
        end

        output :dot => tempfile.path
      end
      tempfile.read
    end

    def draw_tokens(doc)
      # place radius (outer)
      pr = 6
      # place radius (inner = with padding)
      pri = pr * 0.8

      texts = doc.search('text')
      texts.each do |text|
        circle = (text.parent.search('ellipse') || text.parent.search('circle'))[0]
        if circle
          cx = circle[:cx].to_i
          cy = circle[:cy].to_i
          case text.text
          when '0'
          when '1'
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx}" cy="#{cy}" r="#{pri}" />}
          when '2'
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx - pr}" cy="#{cy}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + pr}" cy="#{cy}" r="#{pri}" />}
          when '3'
            fx_bot = 1
            fy_bot = Math.tan(rad(30))
            fx_top = 0
            fy_top = 1 / Math.cos(rad(30))

            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + fx_top * pr}" cy="#{cy - fy_top * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx - fx_bot * pr}" cy="#{cy + fy_bot * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + fx_bot * pr}" cy="#{cy + fy_bot * pr}" r="#{pri}" />}
          when '4'
            fx_bot = fy_bot = fx_top = fy_top = 1

            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx - fx_top * pr}" cy="#{cy - fy_top * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + fx_top * pr}" cy="#{cy - fy_top * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx - fx_bot * pr}" cy="#{cy + fy_bot * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + fx_bot * pr}" cy="#{cy + fy_bot * pr}" r="#{pri}" />}
          when '5'
            fx_bot = fy_bot = fx_top = fy_top = 2 * Math.sin(rad(45))

            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx - fx_top * pr}" cy="#{cy - fy_top * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + fx_top * pr}" cy="#{cy - fy_top * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx - fx_bot * pr}" cy="#{cy + fy_bot * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx + fx_bot * pr}" cy="#{cy + fy_bot * pr}" r="#{pri}" />}
            text.add_next_sibling %Q{<circle fill="#000000" stroke="none" cx="#{cx}" cy="#{cy}" r="#{pri}" />}
          else
            raise "Cannot draw dots for #{text.text} tokens"
          end
          text.remove
        end
      end
      doc
    end

    def remove_rectangles(doc)
      polygons = doc.xpath('//svg:polygon[@fill="#ffffff" and @stroke="#000000"]', 'svg' => 'http://www.w3.org/2000/svg')
      polygons.each do |polygon|
        polygon.remove
      end
      doc
    end

    def rad(y)
      y % 360 * Math::PI / 180
    end
  end
end
