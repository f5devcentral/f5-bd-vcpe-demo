#!/bin/bash

for customer in `seq $1 $2` ; do

	echo "Creating customer with ID $customer"


	sed -e "s/@customer_id/$customer/" < create-customer.variables.yml.tmpl > create-customer.variables.yml


	tower-cli job launch --job-template 15 --extra-vars @create-customer.variables.yml


	echo
	echo

done

