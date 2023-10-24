#!/bin/bash

# Generate a zip file with no extra subdirectory.

mkdir tmp
cd starterkit
zip -r ../tmp/starterkit.zip .
