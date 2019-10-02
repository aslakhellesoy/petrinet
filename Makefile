SHELL := /usr/bin/env bash
PNML_FILES=$(wildcard examples/**/*.xml)
SVG_FILES=$(wildcard examples/**/**/*.svg)
RUBY_FILES=$(wildcard lib/**/*.rb)

.SECONDARY:

default: .rspec_ok pngs examples/cucumber-protocol/transition_sample_1.gif

.rspec_ok: Gemfile.lock $(RUBY_FILES)
	bundle exec rspec
	touch $@

Gemfile.lock: Gemfile
	bundle install
	touch $@

pngs: $(patsubst %.xml,%.png,$(PNML_FILES)) $(patsubst %.svg,%.png,$(SVG_FILES))
.PHONY: pngs

%.png: %.svg
	convert $< $@

%.svg: %.xml Gemfile.lock $(RUBY_FILES) exe/petrinet
	ruby -Ilib exe/petrinet $< > $@

examples/cucumber-protocol/transition_sample_1/000.svg: examples/cucumber-protocol/cucumber-protocol.xml Gemfile.lock $(RUBY_FILES) exe/petrinet
	ruby -Ilib exe/petrinet -t Start -t "PickleStep" -t "PickleStep" -o examples/cucumber-protocol/transition_sample_1 examples/cucumber-protocol/cucumber-protocol.xml

examples/cucumber-protocol/transition_sample_1.gif: examples/cucumber-protocol/transition_sample_1/000.png
	convert -delay 100 -loop 0 examples/cucumber-protocol/transition_sample_1/*.png $@

clean:
	rm -f examples/**/*.{svg,png,gif} examples/**/**/*.{svg,png} .rspec_ok
.PHONY: clean

clobber: clean
	rm -f Gemfile.lock
.PHONY: clobber
