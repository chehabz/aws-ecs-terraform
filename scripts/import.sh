#!/bin/bash
set -e

echo "Connecting to the database in ${1} environment at endpoint ${3}"
#make sure no open connections are established
chmod 400 ~/.ssh/key.pem
ssh -i ~/.ssh/key.pem -o StrictHostKeyChecking=no -L 5432:${3}:5432 ec2-user@bastion.${1}.r-n-p.net -fN &
## todo: check if a table exists and if data is available
## then exit
echo "Importing the database"
PGPASSWORD=${2} psql --host=localhost --username db_admin --no-password -d dbname < ./database/schema.pgsql
echo "Importing the meta data"
PGPASSWORD=${2} psql --host=localhost --username db_admin --no-password -d dbname < ./database/data.pgsql
kill $!