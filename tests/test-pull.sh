#!/bin/sh

BASE=`pwd`/test-pull
export LIT_CONFIG=$BASE/config
APP_DIR=$BASE/app
rm -rf $BASE
mkdir $BASE
echo "database: $BASE/db.git" > $LIT_CONFIG
echo "storage: git" >> $LIT_CONFIG

export LUVI_APP=`pwd`:
luvit auth creationix || exit -1
luvit up localhost || exit -1

mkdir $APP_DIR
cp package.lua $APP_DIR
cd $APP_DIR
luvit install || exit -1
cd -

APP_DIR=$BASE/app2

mkdir $APP_DIR
cp package.lua $APP_DIR
cd $APP_DIR
luvit install || exit -1
cd -

luvit down || exit -1

APP_DIR=$BASE/app3

mkdir $APP_DIR
cp package.lua $APP_DIR
cd $APP_DIR
luvit install || exit -1
cd -
