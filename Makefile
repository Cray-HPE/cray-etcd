# Copyright 2019-2021 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# (MIT License)

CHART_PATH ?= kubernetes
CHART_NAME_1 ?= cray-etcd-backup
CHART_NAME_2 ?= cray-etcd-defrag
CHART_NAME_3 ?= cray-etcd-operator
CHART_VERSION_1 ?= local
CHART_VERSION_2 ?= local
CHART_VERSION_3 ?= local

charts: chart1 chart2 chart3

chart1:
	helm dep up ${CHART_PATH}/${CHART_NAME_1}
	helm package ${CHART_PATH}/${CHART_NAME_1} -d ${CHART_PATH}/.packaged --version ${CHART_VERSION_1}

chart2:
	helm dep up ${CHART_PATH}/${CHART_NAME_2}
	helm package ${CHART_PATH}/${CHART_NAME_2} -d ${CHART_PATH}/.packaged --version ${CHART_VERSION_2}

chart3:
	helm dep up ${CHART_PATH}/${CHART_NAME_3}
	helm package ${CHART_PATH}/${CHART_NAME_3} -d ${CHART_PATH}/.packaged --version ${CHART_VERSION_3}
