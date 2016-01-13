#!/usr/bin/env python3

import pierone.api
import tokens
import sys

if len(sys.argv) < 2:
    print("Usage: prepare-docker <pierone url>")
    sys.exit(1)

pierone_url = sys.argv[1]
print("Preparing configuration for Docker repository {} ...".format(pierone_url))

tokens.manage('application', ['uid', 'application.read', 'application.write'])
token = tokens.get('application')

pierone.api.docker_login_with_token(pierone_url, token)
