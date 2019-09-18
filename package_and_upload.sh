#!/bin/sh
rm function.zip
zip function.zip nmap* -r nse* -r scripts

aws lambda update-function-code --function-name aws-nmap --zip-file fileb://function.zip
