#!/bin/bash -e

cd $(dirname $0)

. utils
. ../../environment

oc create -f - <<EOF || true
kind: ImageStream
apiVersion: v1
metadata:
  name: emailroute
  labels:
    service: emailroute
    function: application
EOF

oc create -f - <<EOF
kind: List
apiVersion: v1
items:
- kind: DeploymentConfig
  apiVersion: v1
  metadata:
    name: emailroute
    labels:
      service: emailroute
      function: application
  spec:
    replicas: 1
    selector:
      service: emailroute
      function: application
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          service: emailroute
          function: application
      spec:
        containers:
        - name: emailroute
          image: emailroute:latest
          ports:
          - containerPort: 8778
            name: jolokia
          env:
          - name: JAVA_OPTS
            value: "-server -XX:+UseCompressedOops -verbose:gc -Xloggc:/opt/eap/standalone/log/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=3M -XX:-TraceClassUnloading -Xms128m -Xmx512m -XX:MaxPermSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=org.jboss.logmanager -Djava.awt.headless=true -Djboss.modules.policy-permissions=true -Xbootclasspath/p:/opt/eap/jboss-modules.jar:/opt/eap/modules/system/layers/base/org/jboss/logmanager/main/jboss-logmanager-1.5.4.Final-redhat-1.jar:/opt/eap/modules/system/layers/base/org/jboss/logmanager/ext/main/javax.json-1.0.4.jar:/opt/eap/modules/system/layers/base/org/jboss/logmanager/ext/main/jboss-logmanager-ext-1.0.0.Alpha2-redhat-1.jar -Djava.util.logging.manager=org.jboss.logmanager.LogManager -javaagent:/opt/eap/jolokia.jar=port=8778,host=0.0.0.0,discoveryEnabled=false"
          - name: MQ_SERVICE_PREFIX_MAPPING
            value: amq
          - name: AMQ_TCP_SERVICE_HOST
            value: amqbroker
          - name: AMQ_TCP_SERVICE_PORT
            value: "61616"
          - name: amq_JNDI
            value: "java:/ConnectionFactory"
          - name: amq_USERNAME
            value: admin
          - name: amq_PASSWORD
            value: admin
    triggers:
    - type: ConfigChange
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
        - emailroute
        from:
          kind: ImageStreamTag
          name: emailroute:latest

# not actually required, but makes UI prettier in beta4
- kind: Service
  apiVersion: v1
  metadata:
    name: emailroute
    labels:
      service: emailroute
      function: application
  spec:
    ports:
    - port: 80
      targetPort: 8080
    selector:
      service: emailroute
      function: application
EOF
