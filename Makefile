SHELL := /usr/bin/env bash
PNML_FILES=$(wildcard examples/**/*.xml)
RUBY_FILES=$(wildcard lib/**/*.rb)

.SECONDARY:

default: .rspec_ok pngs

.rspec_ok: Gemfile.lock $(RUBY_FILES)
	bundle exec rspec
	touch $@

Gemfile.lock: Gemfile
	bundle install
	touch $@

pngs: $(patsubst %.xml,%.png,$(PNML_FILES))
.PHONY: pngs

%.png: %.svg
	convert $< $@

%.svg: %.xml Gemfile.lock $(RUBY_FILES) bin/petrinet
	ruby -Ilib bin/petrinet $< > $@

clean:
	rm -f examples/**/*.{dot,svg,png} .rspec_ok
.PHONY: clean

clobber: clean
	rm -f Gemfile.lock
.PHONY: clobber
