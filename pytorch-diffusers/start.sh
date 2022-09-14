#!/bin/bash

jupyter lab --NotebookApp.token="${PASSWORD}" --ip=0.0.0.0 &

sudo /usr/sbin/sshd -D -o ListenAddress=0.0.0.0 &