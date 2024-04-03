build: build-heroku-18 build-heroku-20 build-heroku-22

build-heroku-18:
	@echo "Building pgbouncer in Docker for heroku-18..."
	@docker run -v $(shell pwd):/buildpack --rm -it -e "STACK=heroku-18" -w /buildpack heroku/heroku:18-build support/pgbouncer-build

build-heroku-20:
	@echo "Building pgbouncer in Docker for heroku-20..."
	@docker run -v $(shell pwd):/buildpack --rm -it -e "STACK=heroku-20" -w /buildpack heroku/heroku:20-build support/pgbouncer-build

build-heroku-22:
	@echo "Building pgbouncer in Docker for heroku-22..."
	@docker run -v $(shell pwd):/buildpack --rm -it -e "STACK=heroku-22" -w /buildpack heroku/heroku:22-build support/pgbouncer-build

shell:
	@echo "Opening heroku-22 shell..."
	@docker run -v $(shell pwd):/buildpack --rm -it -e "STACK=heroku-22" -e "PORT=5000" -w /buildpack heroku/heroku:22-build bash
