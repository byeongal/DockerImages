#!/bin/bash

echo "SSH Server Start"
sudo service ssh restart

echo "Jupyter Lab Start"
jupyter lab --NotebookApp.token="${PASSWORD}" --ip=0.0.0.0 &

tail -f /dev/null