APPNAME = quickpony-roku
VERSION = 1.0
DEVPASSWORD=1141
ZIP_EXCLUDE= -x \*.pkg -x storeassets\* -x stuff\* -x keys\* -x \*/.\* -x Makefile -x app.mk -x README.md -x secrets_template.brs -x .git\* -x .project -x .DS_Store
include app.mk
