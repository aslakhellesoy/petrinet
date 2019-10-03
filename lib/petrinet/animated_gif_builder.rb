module Petrinet
  class AnimatedGifBuilder
    def initialize(net)
      @net = net
    end

    def write(transition_names, gif_path)
      @image_number = 0
      Dir.mktmpdir('petrinet-animation') do |tmpdir|
        net = @net

        write_png(net, tmpdir)
        transition_names.each do |transition_name|
          firing = net.prefire(transition_name)
          write_png(firing, tmpdir)
          net = net.fire(transition_name)
          write_png(net, tmpdir)
        end

        STDOUT.write "🎬\n"
        `convert -delay 100 -loop 0 #{tmpdir}/*.png #{gif_path}`
      end
    end

    private

    def write_png(net, tmpdir)
      number_string = '%04d' % @image_number
      svg_path = "#{tmpdir}/#{number_string}.svg"
      png_path = "#{tmpdir}/#{number_string}.png"
      File.open(svg_path, 'w:UTF-8') {|io| io.puts(net.to_svg)}
      STDOUT.write "👀️"
      `convert #{svg_path} #{png_path}`
      @image_number += 1
    end
  end
end
