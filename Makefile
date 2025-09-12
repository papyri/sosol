.PHONY: build test

build:
	docker build -t ${build_tag} --build-arg RUBY_VERSION=${RBENV_VERSION} --build-arg BUNDLE_GEMFILE=${BUNDLE_GEMFILE} .

test:
	docker compose -f docker-compose-test.yml up --abort-on-container-exit --exit-code-from app
