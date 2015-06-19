#!/bin/bash -e

cd $(dirname $0)

. utils
. ../../environment

osc create -f - <<EOF || true
kind: ImageStream
apiVersion: v1beta1
metadata:
  name: emailroute
  labels:
    service: emailroute
    function: application
EOF

osc create -f - <<EOF
kind: List
apiVersion: v1beta3
items:
- kind: DeploymentConfig
  apiVersion: v1beta1
  metadata:
    name: emailroute
    labels:
      service: emailroute
      function: application
  triggers:
  - type: ConfigChange
  - type: ImageChange
    imageChangeParams:
      automatic: true
      containerNames:
      - emailroute
      from:
        name: emailroute
      tag: latest
  template:
    strategy:
      type: Recreate
    controllerTemplate:
      replicas: 1
      replicaSelector:
        service: emailroute
        function: application
      podTemplate:
        desiredState:
          manifest:
            version: v1beta2
            containers:
            - name: emailroute
              image: emailroute:latest
              ports:
              - containerPort: 8778
                name: jolokia
              env:
              - name: MQ_SERVICE_PREFIX_MAPPING
                value: amq
              - name: AMQ_TCP_SERVICE_HOST
                value: broker
              - name: AMQ_TCP_SERVICE_PORT
                value: "61616"
              - name: amq_JNDI
                value: "java:/ConnectionFactory"
              - name: amq_USERNAME
                value: admin
              - name: amq_PASSWORD
                value: admin
        labels:
          service: emailroute
          function: application
EOF
