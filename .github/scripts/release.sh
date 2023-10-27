#!/bin/bash

# Generate a zip file with no extra subdirectory.
# We do this to make a zip that single_content_sync
# can import correctly.

mkdir tmp
cd starterkit
zip -r ../tmp/starterkit.zip .
