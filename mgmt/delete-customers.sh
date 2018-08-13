#!/bin/bash

for customer in `seq $1 $2` ; do

	sed -e "s/@customer_id/$customer/" < delete-customer.variables.yml.tmpl > delete-customer.variables.yml
	tower-cli job launch --job-template 16 --extra-vars @delete-customer.variables.yml

done

