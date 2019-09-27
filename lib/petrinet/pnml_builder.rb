require 'nokogiri'

module Petrinet
  class PnmlBuilder
    def initialize(xml)
      @xml = xml
    end

    def net
      doc = Nokogiri::XML(@xml)

      transitions = Hash.new {|h, k| h[k] = {take: [], give: []}}
      markings = Hash.new

      doc.xpath('//place').each do |place|
        place_name = place[:id].to_sym
        initial_marking_nodes = place.xpath('initialMarking/value/text()')
        initial_marking = initial_marking_nodes.empty? ? 0 : initial_marking_nodes[0].text.split(',')[1].to_i
        markings[place_name] = initial_marking
      end

      doc.xpath('//transition').each do |transition|
        transition_name = transition[:id].to_sym
        transitions[transition_name]
      end

      doc.xpath('//arc').each do |arc|
        source_name = arc[:source].to_sym
        target_name = arc[:target].to_sym

        if transitions.has_key?(source_name)
          transition_name = source_name
          place_name = target_name
          transitions[transition_name][:give] << place_name
        elsif transitions.has_key?(target_name)
          transition_name = target_name
          place_name = source_name
          transitions[transition_name][:take] << place_name
        else
          raise "Unknown transition name in one of: #{source_name} -> #{target_name}"
        end
      end

      net = Net.build do
        transitions.each do |transition_name, places|
          transition(transition_name, take: places[:take], give: places[:give])
        end
      end
      net.mark(markings)
    end
  end
end
