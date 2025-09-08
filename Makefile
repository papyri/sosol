.PHONY: build test

build:
	docker build -t ${build_tag} .

test:
	docker compose -f docker-compose-test.yml up --abort-on-container-exit --exit-code-from app
