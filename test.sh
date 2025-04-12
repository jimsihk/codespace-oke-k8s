#!/bin/bash

set -eo pipefall

echo "Installed versions:"
echo "- oci: $(oci --version)"
echo "- kubectl:" && kubectl version --client
echo "- helm: $(helm version)"
echo "- git: $(git --version)"
echo "- k9s:" && k9s version
echo "- kdash: $(kdash --version)"
