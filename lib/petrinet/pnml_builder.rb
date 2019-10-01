require 'nokogiri'

module Petrinet
  class PnmlBuilder
    def initialize(xml)
      @xml = xml
    end

    def net
      doc = Nokogiri::XML(@xml)

      transition_by_id = {}
      place_by_id = {}
      edges = []

      transitions = Hash.new {|h, k| h[k] = {take: [], give: []}}
      markings = Hash.new

      # https://github.com/bitwrap/bitwrap-io/blob/master/bitwrap_io/machine/pnml.py#L216

      doc.xpath('//place').each do |place_node|
        place_id = place_node[:id].to_sym
        initial_marking_nodes = place_node.xpath('initialMarking/value/text()')
        initial_marking = initial_marking_nodes.empty? ? 0 : initial_marking_nodes[0].text.split(',')[1].to_i

        # place = Place.new(initial_marking)
        # place_by_id[place_id] = place

        # TODO: Remove
        markings[place_id] = initial_marking
      end

      doc.xpath('//transition').each do |transition_node|
        transition_id = transition_node[:id].to_sym

        # transition = Transition.new
        # transition_by_id[transition_id] = transition

        # TODO: Remove
        transitions[transition_id]
      end

      doc.xpath('//arc').each do |arc_node|
        source_id = arc_node[:source].to_sym
        target_id = arc_node[:target].to_sym

        # edge = Edge.new(source_id, target_id)
        # edges.push(edge)

        if transitions.has_key?(source_id)
          transition_name = source_id
          place_name = target_id
          transitions[transition_name][:give] << place_name
        elsif transitions.has_key?(target_id)
          transition_name = target_id
          place_name = source_id
          transitions[transition_name][:take] << place_name
        else
          raise "Unknown transition name in one of: #{source_id} -> #{target_id}"
        end
      end

      net = Net.build do |b|
        transitions.each do |transition_name, places|
          b.transition(transition_name, take: places[:take], give: places[:give])
        end
      end
      net.mark(markings)
    end
  end
end
