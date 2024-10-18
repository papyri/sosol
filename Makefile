.PHONY: build

CI_REGISTRY_IMAGE ?= sosol

build:
	docker build -t $(CI_REGISTRY_IMAGE):latest .
