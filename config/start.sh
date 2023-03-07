#!/bin/bash
cd /opt/td-agent-bit/bin; ./td-agent-bit -c fluentbit.conf > fluentbit.log 2>&1 &
nginx -g "daemon off;"
