#!/bin/bash

echo "===== Bash Assignment ====="

echo "User: $(whoami)"
echo "Host: $(hostname)"
echo "Date: $(date)"

echo "Files count:"
ls | wc -l

echo "Enter your name:"
read name
echo "Hello, $name!"
