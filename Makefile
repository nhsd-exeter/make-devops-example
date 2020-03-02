PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

project-config:
	make docker-config

project-build: project-config
	make service1-image

project-start:
	make docker-compose-start YML=$(DOCKER_COMPOSE_YML)

project-stop:
	make docker-compose-stop YML=$(DOCKER_COMPOSE_YML)

project-log:
	make docker-compose-log YML=$(DOCKER_COMPOSE_YML)

# ==============================================================================

artefact-ui: build-ui

build-ui:
	make docker-run-node \
		DIR=application/ui \
		CMD="yarn install"

artefact-service1: build-service1
	cp -v \
		$(APPLICATION_DIR)/service1/target/demo-*.jar \
		$(DOCKER_DIR)/service1/assets/application/service1.jar
	make docker-image NAME=service1

build-service1:
	make docker-run-mvn \
		DIR=application/service1 \
		CMD="-Dmaven.test.skip=true clean package"

debug-service1:
	make project-start 2> /dev/null ||:
	docker rm --force service1 2> /dev/null ||:
	make docker-run-mvn \
		CONTAINER=service1 \
		DIR=application/service1 \
		CMD="spring-boot:run \
			-Dspring-boot.run.jvmArguments=' \
				-Xdebug \
				-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=*:9999 \
			' \
		" \
		ARGS=" \
			--env PROFILE='$(PROFILE)' \
			\
			--publish 8081:8080 \
			--publish 9999:9999 \
		"
		make project-start

# ==============================================================================

.SILENT:
