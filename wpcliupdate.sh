#!/bin/bash

# update wordpress
wp core update
wp theme update --all
wp plugin update --all