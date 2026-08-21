package main

# Do Not store secrets in ENV variables
secrets_env := [
    "passwd",
    "password",
    "pass",
    "secret",
    "key",
    "access",
    "api_key",
    "apikey",
    "token",
    "tkn",
]

deny contains msg if {
    some i
    input[i].Cmd == "env"
    val := input[i].Value
    contains(lower(val[_]), secrets_env[_])
    msg := sprintf("Line %d: Potential secret in ENV key found: %s", [i, val])
}


# Only use trusted base images
deny contains msg if {
    some i
    input[i].Cmd == "from"
    val := split(input[i].Value[0], "/")
    count(val) > 1
    msg := sprintf("Line %d: use a trusted base image", [i])
}


# Do not use 'latest' tag for base images
deny contains msg if {
    some i
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    count(val) > 1
    contains(lower(val[1]), "latest")
    msg := sprintf("Line %d: do not use 'latest' tag for base images", [i])
}


# Avoid curl bashing
deny contains msg if {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    matches := regex.find_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
    count(matches) > 0
    msg := sprintf("Line %d: Avoid curl bashing", [i])
}


# Do not upgrade your system packages
warn contains msg if {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    matches := regex.match(
        ".*?(apk|yum|dnf|apt|pip).+?(install|[dist-|check-|group]?up[grade|date]).*",
        lower(val),
    )
    matches == true
    msg := sprintf("Line: %d: Do not upgrade your system packages: %s", [i, val])
}


# Do not use ADD if possible
deny contains msg if {
    some i
    input[i].Cmd == "add"
    msg := sprintf("Line %d: Use COPY instead of ADD", [i])
}


# Any user...
any_user if {
    some i
    input[i].Cmd == "user"
}


# ... but do not run as root
deny contains msg if {
    not any_user
    msg := "Do not run as root, use USER instead"
}


# Forbidden users
forbidden_users := [
    "root",
    "toor",
    "0",
]

deny contains msg if {
    some i
    input[i].Cmd == "user"
    users := [name |
        some j
        input[j].Cmd == "user"
        name := input[j].Value
    ]

    lastuser := users[count(users) - 1]

    contains(lower(lastuser[_]), forbidden_users[_])

    msg := sprintf(
        "Line %d: Last USER directive (USER %s) is forbidden",
        [i, lastuser],
    )
}


# Do not sudo
deny contains msg if {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(lower(val), "sudo")
    msg := sprintf("Line %d: Do not use 'sudo' command", [i])
}


# Use multi-stage builds
default multi_stage := false

multi_stage if {
    some i
    input[i].Cmd == "copy"
    val := concat(" ", input[i].Flags)
    contains(lower(val), "--from=")
}

deny contains msg if {
    multi_stage == false
    msg := "You COPY, but do not appear to use multi-stage builds..."
}
