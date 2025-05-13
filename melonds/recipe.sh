#!/bin/bash

wget https://github.com/RetroDECK/net.kuribo64.melonDS/releases/latest/download/RetroDECK-melonds-Artifact.tar.gz

mkdir melonds-tmp

mkdir melonds

tar -xzf RetroDECK-melonds-Artifact.tar.gz -C melonds-tmp

mv melonds-tmp/files/bin/ melonds/
mv melonds-tmp/files/lib/ melonds/
mv melonds-tmp/files/share/ melonds/

cp component_launcher.sh manifest.json functions.sh prepare_component.sh melonds/
chmod +x melonds/component_launcher.sh

tar -czf "melonds-artifact.tar.gz" "melonds"

rm -rf melonds-tmp
rm -rf melonds
