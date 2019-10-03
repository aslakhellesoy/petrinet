SHELL := /usr/bin/env bash
PNML_FILES=$(wildcard examples/**/*.xml)
SVG_FILES=$(wildcard examples/**/**/*.svg)
RUBY_FILES=$(wildcard lib/**/*.rb)

.SECONDARY:

default: .rspec_ok examples/cucumber-protocol/transition_sample_1.gif examples/x-ray-machine/v1-problem.gif

.rspec_ok: Gemfile.lock $(RUBY_FILES)
	bundle exec rspec
	touch $@

Gemfile.lock: Gemfile
	bundle install
	touch $@

examples/cucumber-protocol/transition_sample_1.gif: examples/cucumber-protocol/cucumber-protocol.xml Gemfile.lock $(RUBY_FILES) exe/petrinet
	ruby -Ilib exe/petrinet -t "Start" -t "PickleStep" -t "PickleStep" -o $@ $<

examples/x-ray-machine/v1-problem.gif: examples/x-ray-machine/x-ray-machine-1.xml Gemfile.lock $(RUBY_FILES) exe/petrinet
	ruby -Ilib exe/petrinet -t "enter" -t "make_photo" -t "enter" -t "enter" -o $@ $<

clean:
	rm -f examples/**/*.gif .rspec_ok
.PHONY: clean

clobber: clean
	rm -f Gemfile.lock
.PHONY: clobber
