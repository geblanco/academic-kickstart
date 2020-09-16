#!/bin/bash

if ! test academic; then
  echo "academic not installed, do so with \`pip install -U academic\`"
  exit 1
fi

academic import --bibtex publications/*.bib
