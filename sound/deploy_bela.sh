#!/usr/bin/env bash

echo "Deploying Bela project..."

rsync -rvt dephone-bela/ root@bela.local:/root/Bela/projects/dephone-bela/
rsync -rvt renders root@bela.local:/root/Bela/projects/dephone-sounds/
