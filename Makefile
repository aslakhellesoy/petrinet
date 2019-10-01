SHELL := /usr/bin/env bash
PNML_FILES=$(wildcard examples/**/*.xml)
SVG_FILES=$(wildcard examples/**/**/*.svg)
RUBY_FILES=$(wildcard lib/**/*.rb)

.SECONDARY:

default: .rspec_ok pngs examples/cucumber-protocol/transition_sample_1/000.svg

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

%.svg: %.xml Gemfile.lock $(RUBY_FILES) bin/petrinet
	ruby -Ilib bin/petrinet $< > $@

examples/cucumber-protocol/transition_sample_1/000.svg: examples/cucumber-protocol/cucumber-protocol.xml Gemfile.lock $(RUBY_FILES) bin/petrinet
	ruby -Ilib ./bin/petrinet -t Start -t "PickleStep" -t "PickleStep" -o examples/cucumber-protocol/transition_sample_1 examples/cucumber-protocol/cucumber-protocol.xml

clean:
	rm -f examples/**/*.{svg,png} examples/**/**/*.{svg,png} .rspec_ok
.PHONY: clean

clobber: clean
	rm -f Gemfile.lock
.PHONY: clobber
