RSpec.describe Petrinet::Net do
  # p1(.)->t|->p2( )
  describe 'single transition' do
    before do
      pn = Petrinet::Net.build do |b|
        b.transition(:t, take: :p1, give: :p2)
      end
      @pn = pn.mark(p1: 1)
    end

    it "does not allow a transition" do
      @pn = @pn.fire(:t)
      expect do
        @pn.fire(:t)
      end.to raise_error('Cannot fire: t')
    end

    it "enumerates fireable states" do
      expect(@pn.fireable).to eq(Set[:t])
    end
  end

  # p1(.)->t[]->p2( )
  # ^-------|
  describe 'single transition with feedback' do
    before do
      pn = Petrinet::Net.build do |b|
        b.transition(:t, take: :p1, give: [:p1, :p2])
      end
      @pn = pn.mark(p1: 1)
    end

    it "allows indefinite transition" do
      @pn = @pn.fire(:t)
      @pn = @pn.fire(:t)
      @pn = @pn.fire(:t)
    end

    it "enumerates fireable states" do
      expect(@pn.fireable).to eq(Set[:t])
    end
  end

  describe ".from_pnml" do
    it "builds a net" do
      pn = Petrinet::Net.from_pnml(IO.read(File.dirname(__FILE__) + '/../../examples/voting/voting.xml'))
      pn = pn.fire(:YAY)
      pn = pn.fire(:YAY)
      pn = pn.fire(:YAY)
      expect do
        pn.fire(:YAY)
      end.to raise_error('Cannot fire: YAY')
    end
  end

  describe ".to_svg" do
    it "produces an svg" do
      pn = Petrinet::Net.from_pnml(IO.read(File.dirname(__FILE__) + '/../../examples/voting/voting.xml'))
      svg = pn.to_svg
    end
  end
end
