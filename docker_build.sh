#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker build --network=host -f ${SCRIPT_DIR}/Dockerfile -t mplab/build:latest .
