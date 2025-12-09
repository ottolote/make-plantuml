#!/bin/bash
while true; do
  find . -name "*.pu" | entr -p make
done