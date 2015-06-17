#!/bin/bash -e

cd $(dirname $0)

. utils
. ../environment

PROJECT=$(osc status | sed -n '1 { s/.* //; p; }')

osc create -f - <<EOF || true
kind: ImageStream
apiVersion: v1beta1
metadata:
  name: camel
  labels:
    component: camel
EOF

osc create -f - <<EOF
kind: BuildConfig
apiVersion: v1beta1
metadata:
  name: camel
  labels:
    component: camel
triggers:
- type: generic
  generic:
    secret: secret
parameters:
  strategy:
    type: STI
    stiStrategy:
      image: docker.io/cicddemo/sti-eap
      env:
      - name: MAVEN_MIRROR
        value: "http://192.168.0.254:8081/nexus/content/groups/public"
  source:
    type: Git
    git:
      ref: master
      uri: http://gogs.gogs/$PROJECT/camel
  output:
    to:
      name: camel
EOF
