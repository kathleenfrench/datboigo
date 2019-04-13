
WHOAMI ?= $(shell whoami)
CWD := $(shell pwd)
PROJECT_NAME := datboigo
BIN_NAME := datboigo
TODAY = $(shell date +%Y-%m-%d.%H:%M:%S)
INSTALL_LOCATION := /usr/local/bin

UNAME_S := $(shell uname -s)
ifeq ($(PLATFORM),)
ifeq ($(UNAME_S),Darwin)
PLATFORM ?= darwin
endif
ifeq ($(UNAME_S),Linux)
PLATFORM ?= linux
endif
endif

ifndef GITHUB_USER
GITHUB_USER := $(shell security find-internet-password -s github.com | grep acct | sed 's/"acct"<blob>="//g' | sed 's/"//g')
endif

GO := $(shell command -v go 2>/dev/null)
GOOS = $(PLATFORM)
GOARCH ?= amd64
GO_VERSION_CMD = $(GO) version | cut -d' ' -f 3
GO_VERSION = $(shell $(GO_VERSION_CMD))
DESIRED_GO_VERSION := go1.10.5
BUILD_OUTPUT_DIR := $(CWD)/build
BINARY_LOCATION := $(BUILD_OUTPUT_DIR)/$(BIN_NAME)
GO_LINK_VARS = -X 'main.buildTime=$(TODAY)' -X 'main.buildTag=$(DOCKER_TAG)' -X 'main.builder=$(WHOAMI)' -X 'main.buildGoVersion=$(GO_VERSION)' -X 'main.buildDepVersion=$(DEP_VERSION)' -X 'main.buildAppName=$(PROJECT_NAME)'
GIT_VARS = -X 'main.gituser=$(GITHUB_USER)'
GO_LINKER_FLAGS = "$(GO_LINK_VARS) $(GIT_VARS)"
GO_BUILD_FLAGS = -a --installsuffix cgo -ldflags $(GO_LINKER_FLAGS) -o $(BINARY_LOCATION)
ifdef BUILD_DEBUG
GO_BUILD_FLAGS += -x -v
endif

BUILD_OUTPUT_DIR := $(CWD)/build
BINARY_LOCATION := $(BUILD_OUTPUT_DIR)/$(BIN_NAME)

DESIRED_DEP_VERSION := v0.5.0
DEP_URL = https://github.com/golang/dep/releases/download/$(DESIRED_DEP_VERSION)
DEP_INSTALL_LOCATION ?= $(CWD)/dep
DEP := $(shell command -v dep 2>/dev/null)
ifeq ($(DEP),)
DEP += $(DEP_INSTALL_LOCATION)
endif
DEP_VERSION_CMD = $(DEP) version | grep -e '^ version' | cut -d':' -f 2 | xargs | cut -d'-' -f 1 ## lazy evaluated in case DEP changes
DEP_VERSION = $(shell $(DEP_VERSION_CMD))
DEP_ENSURE_FLAGS := -vendor-only
ifdef BUILD_DEBUG
DEP_ENSURE_FLAGS += -v
endif
ifneq ($(DESIRED_DEP_VERSION),$(DEP_VERSION))
DEP := $(DEP_INSTALL_LOCATION)
endif

PACKR := $(shell command -v packr 2>/dev/null)
ifeq ($(PACKR),)
PACKR := $(GOPATH)/bin/packr
endif

${PACKR}:
	@if ! [ -x $(PACKR) ]; then \
		echo "packr missing, installing packr"; \
		go get -u github.com/gobuffalo/packr/...; \
	fi;

${GO}:
	@if ! [ -x $(GO) ]; then \
		echo "golang not installed! please install $(DESIRED_GO_VERSION)."; \
		exit 2
	fi;

${DEP}:
	@if ! [ -x $(DEP) ]; then \
		echo "dep not installed. installing $(DEP_URL)/dep-$(GOOS)-amd64 to $(DEP_INSTALL_LOCATION)."; \
		curl -L -o $(DEP_INSTALL_LOCATION) $(DEP_URL)/dep-$(GOOS)-amd64; \
		chmod ugo+x $(DEP_INSTALL_LOCATION); \
	fi;

${BUILD_OUTPUT_DIR}:
	@echo "generating build dir $(BUILD_OUTPUT_DIR)..."
	@mkdir -p $(BUILD_OUTPUT_DIR)

.PHONY: ensure_dep_version
ensure_dep_version: ${DEP} ## Enforces that we have a copy of dep that matches the desired version
	@if [ '$(DEP_VERSION)' != '$(DESIRED_DEP_VERSION)' ]; then \
		echo "wanted dep version $(DESIRED_DEP_VERSION), got $(DEP_VERSION)."; \
		echo "installing $(DEP_URL)/dep-$(GOOS)-amd64 to $(DEP_INSTALL_LOCATION)."; \
		curl -L -o $(DEP_INSTALL_LOCATION) $(DEP_URL)/dep-$(GOOS)-amd64; \
		chmod ugo+x $(DEP_INSTALL_LOCATION); \
	fi;

.PHONY: dependencies
dependencies: ensure_dep_version ## install dependencies
	@echo "installing dependencies in $(DEP_INSTALL_LOCATION)..."
	$(DEP) ensure $(DEP_ENSURE_FLAGS)

.PHONY: test
test: dependencies ## Run tests
	@echo "running tests..."
	@$(GO) test -cover -vet all ./...

.PHONY: build
build: test ${PACKR} ${BUILD_OUTPUT_DIR} ## Performs a build only if tests pass
	@echo "building for $(GOOS)_$(GOARCH)"
	@packr
	@cd $(CWD)/cmd/$(BIN_NAME) && \
		export GOOS=$(GOOS) GOARCH=$(GOARCH) && \
		export CGO_ENABLED=0 && \
		export GITHUB_USER=$(GITHUB_USER) && \
		$(GO) build ${GO_BUILD_FLAGS}
		echo "binary compiled to $(BINARY_LOCATION)"
	@cd $(CWD) && packr clean

.PHONY: install
install: build
	@echo "installing to ${INSTALL_LOCATION}"
	cp ${BINARY_LOCATION} ${INSTALL_LOCATION}

.PHONY: run
run: dependencies
	cd cmd/datboigo && go run **.go

.PHONY: docker_build
docker_build:
	docker build -t datboigo .

.PHONY: docker_run
docker_run:
	docker run -i -t datboigo