.PHONY: build

build_tag ?= papyri-editor

build:
	docker build -t $(build_tag):latest .
