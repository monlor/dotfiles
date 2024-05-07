#!/bin/bash

if [ ! -d "91QiuChen" ]; then
  git clone https://github.com/QiuChenlyOpenSource/91QiuChen
fi

cd 91QiuChen

git pull

./秋城落叶_启动.command

cd ..
