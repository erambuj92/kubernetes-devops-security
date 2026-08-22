package main

deny contains msg if {
    input.kind == "Service"
    not input.spec.type == "NodePort"
    msg := "Service Type should be NodePort"
}

deny contains msg if {
    input.kind == "Deployment"
    not input.spec.template.spec.containers[0].securityContext.runAsNonRoot == true
    msg := "Containers must not run as root - use runAsNonRoot within container securityContext"
}
