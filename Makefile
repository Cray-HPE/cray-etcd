# Copyright 2021 Hewlett Packard Enterprise Development LP

CHART_METADATA_IMAGE ?= artifactory.algol60.net/csm-docker/stable/chart-metadata
YQ_IMAGE ?= artifactory.algol60.net/docker.io/mikefarah/yq:4
HELM_IMAGE ?= artifactory.algol60.net/csm-docker/stable/docker.io/alpine/helm:3.9.4
HELM_UNITTEST_IMAGE ?= artifactory.algol60.net/csm-docker/stable/docker.io/quintush/helm-unittest:latest
HELM_DOCS_IMAGE ?= artifactory.algol60.net/csm-docker/stable/docker.io/jnorwood/helm-docs:v1.5.0

all: dep-up lint test package

helm:
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		--mount type=bind,src="$(shell pwd)",dst=/src \
		-w /src \
		-e HELM_CACHE_HOME=/src/.helm/cache \
		-e HELM_CONFIG_HOME=/src/.helm/config \
		-e HELM_DATA_HOME=/src/.helm/data \
		$(HELM_IMAGE) \
		$(CMD)

lint:
	CMD="lint charts/cray-etcd-backup"          $(MAKE) helm
	CMD="lint charts/cray-etcd-defrag"          $(MAKE) helm
	CMD="lint charts/cray-etcd-base"            $(MAKE) helm
	CMD="lint charts/cray-etcd-migration-setup" $(MAKE) helm

dep-up:
	CMD="dep up charts/cray-etcd-backup"          $(MAKE) helm
	CMD="dep up charts/cray-etcd-defrag"          $(MAKE) helm
	CMD="dep up charts/cray-etcd-base"            $(MAKE) helm
	CMD="dep up charts/cray-etcd-migration-setup" $(MAKE) helm

test:
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v ${PWD}/charts:/apps \
		${HELM_UNITTEST_IMAGE} \
		cray-etcd-backup \
		cray-etcd-defrag \
		cray-etcd-base \
		cray-etcd-migration-setup

package:
ifdef CHART_VERSIONS
	CMD="package charts/cray-etcd-backup          --version $(word 1, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
	CMD="package charts/cray-etcd-defrag          --version $(word 2, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
	CMD="package charts/cray-etcd-base            --version $(word 3, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
	CMD="package charts/cray-etcd-migration-setup --version $(word 4, $(CHART_VERSIONS)) -d packages" $(MAKE) helm
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
	  CHART=charts/cray-etcd-defrag          $(MAKE) -s extracted-images annotated-images; \
	  CHART=charts/cray-etcd-base            $(MAKE) -s extracted-images annotated-images; \
	  CHART=charts/cray-etcd-migration-setup $(MAKE) -s extracted-images annotated-images; \
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
