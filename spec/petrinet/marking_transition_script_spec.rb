RSpec.describe Petrinet::MarkingTransitionScript do
  it "generates a marking" do
    source = <<-EOF
p1:10
p2:20
p3:30
t1
t2
t3
    EOF

    script = Petrinet::MarkingTransitionScript.new(source)

    expect(script.marking).to eq({p1: 10, p2: 20, p3: 30})
    expect(script.transitions).to eq([:t1, :t2, :t3])
  end
end
