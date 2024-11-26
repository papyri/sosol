.PHONY: build test

CI_REGISTRY_IMAGE ?= sosol
CI_COMMIT_SHORT_SHA ?= $(shell basename $(shell git rev-parse --show-toplevel))

build:
	docker build -t $(CI_REGISTRY_IMAGE)/builds:$(CI_COMMIT_SHORT_SHA) .

test:
	docker compose -f docker-compose-test.yml up --abort-on-container-exit --exit-code-from app
