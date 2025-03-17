# Copyright 2021 Hewlett Packard Enterprise Development LP

CHART_METADATA_IMAGE ?= artifactory.algol60.net/csm-docker/stable/chart-metadata
YQ_IMAGE ?= artifactory.algol60.net/docker.io/mikefarah/yq:4
HELM_IMAGE ?= artifactory.algol60.net/csm-docker/stable/docker.io/alpine/helm:3.9.4
HELM_UNITTEST_IMAGE ?= artifactory.algol60.net/csm-docker/stable/docker.io/quintush/helm-unittest:latest
HELM_DOCS_IMAGE ?= artifactory.algol60.net/csm-docker/stable/docker.io/jnorwood/helm-docs:v1.5.0

ifeq ($(shell uname -s),Darwin)
        HELM_CONFIG_HOME ?= $(HOME)/Library/Preferences/helm
else
        HELM_CONFIG_HOME ?= $(HOME)/.config/helm
endif
COMMA := ,

all: dep-up lint test package

helm:
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		--mount type=bind,src="$(shell pwd)",dst=/src \
                $(if $(wildcard $(HELM_CONFIG_HOME)/.),--mount type=bind$(COMMA)src=$(HELM_CONFIG_HOME)$(COMMA)dst=/tmp/.helm/config) \
		-w /src \
		-e HELM_CACHE_HOME=/src/.helm/cache \
		-e HELM_CONFIG_HOME=/tmp/.helm/config \
		-e HELM_DATA_HOME=/src/.helm/data \
		$(HELM_IMAGE) \
		$(CMD)

lint:
	CMD="lint charts/cray-etcd-backup"          $(MAKE) helm
	CMD="lint charts/cray-etcd-base"            $(MAKE) helm
	CMD="lint charts/cray-etcd-test"            $(MAKE) helm

dep-up:
	CMD="dep up charts/cray-etcd-backup"          $(MAKE) helm
	CMD="dep up charts/cray-etcd-base"            $(MAKE) helm
	CMD="dep up charts/cray-etcd-test"            $(MAKE) helm

test:
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v ${PWD}/charts:/apps \
		${HELM_UNITTEST_IMAGE} \
		cray-etcd-backup \
		cray-etcd-base \
		cray-etcd-test

package:
ifdef CHART_VERSIONS
	CMD="package charts/cray-etcd-backup          --version $(word 1, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
	CMD="package charts/cray-etcd-base            --version $(word 2, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
	CMD="package charts/cray-etcd-test            --version $(word 3, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
else
	CMD="package charts/* -d packages" $(MAKE) helm
endif

extracted-images:
	CMD="template release $(CHART) --dry-run --replace --dependency-update" $(MAKE) -s helm \
	| docker run --rm -i $(YQ_IMAGE) e -N '.. | .image? | select(.)' -

annotated-images:
	CMD="show chart $(CHART)" $(MAKE) -s helm \
	| docker run --rm -i $(YQ_IMAGE) e -N '.annotations."artifacthub.io/images"' - \
	| docker run --rm -i $(YQ_IMAGE) e -N '.. | .image? | select(.)' -

images:
	{ CHART=charts/cray-etcd-backup          $(MAKE) -s extracted-images annotated-images; \
	  CHART=charts/cray-etcd-base            $(MAKE) -s extracted-images annotated-images; \
	  CHART=charts/cray-etcd-test            $(MAKE) -s extracted-images annotated-images; \
	} | sort -u

snyk:
	$(MAKE) -s images | xargs --verbose -n 1 snyk container test

gen-docs:
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		--mount type=bind,src="$(shell pwd)",dst=/src \
		-w /src \
		$(HELM_DOCS_IMAGE) \
		helm-docs --chart-search-root=charts

clean:
	$(RM) -r .helm packages
