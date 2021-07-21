REBAR := $(shell which rebar3 2>/dev/null || which ./rebar3)

.PHONY: all get_deps compile lint check_format \
		format test xref clean distclean dialyze shell

all: compile

get_deps:
	$(REBAR) get-deps

compile:
	$(REBAR) compile

shell:
	$(REBAR) shell

lint:
	$(REBAR) lint

check_format:
	$(REBAR) fmt -c

format:
	$(REBAR) fmt -w

test:
	$(REBAR) do eunit

xref:
	$(REBAR) xref

clean:
	$(REBAR) clean

distclean:
	rm -rfv _build

dialyze:
	$(REBAR) dialyzer

