#!/bin/bash
echo "Preparing the lab, please wait..."
while [ ! -f /tmp/.lab-ready ]; do sleep 1; done
clear
echo "LAB READY - type 'check' at any time to see your progress."
