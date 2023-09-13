#!/bin/bash

if [ ! -d "InjectLib" ]; then
  git clone https://github.com/QiuChenlyOpenSource/InjectLib
fi

cd InjectLib

git pull

sudo ruby main.rb

cd ..
