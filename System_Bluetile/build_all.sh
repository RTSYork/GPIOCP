#!/bin/bash

for f in `ls`; do
	if [ -d $f ]; then
		cd $f; 
		if [ -f build.sh ]; then
			./build.sh
		fi
                cd ../
	fi
done
