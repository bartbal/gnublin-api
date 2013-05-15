OBJ := dogm lcd lm75 pca9555 relay step adcmod
SUBDIRS := $(OBJ:%=gnublin-tools/gnublin-%)
CLEANDIRS := $(SUBDIRS:%=clean-%)
INSTALLDIRS := $(SUBDIRS:%=install-%)
UNINSTALLDIRS := $(SUBDIRS:%=uninstall-%)
COPYDIRS := $(OBJ:%=copy-%)
VERSION = 0.1
Maintainer = embedded projects GmbH <info@embedded-projects.net>
include API-config.mk

.PHONY: gnublin-tools $(SUBDIRS) $(CLEANDIRS) $(INSTALLDIRS)
     
all: build gnublin.o gnublin.a libgnublin.so.1.0.1 gnublin-tools

build:
	sh build-API.sh

gnublin.o: build gnublin.cpp gnublin.h
	$(CXX) $(CXXFLAGS) $(BOARDDEF) $(APIDEFS) -c gnublin.cpp

gnublin.a: gnublin.o 
	ar rcs gnublin.a gnublin.o

libgnublin.so.1.0.1: gnublin.cpp gnublin.h
	$(CXX) $(CXXFLAGS) -c -fPIC gnublin.cpp -o gnublin_fpic.o     
	$(CXX) -shared -Wl,-soname,libgnublin.so.1 -o libgnublin.so.1.0.1  gnublin_fpic.o

#build gnublin-tools
gnublin-tools: gnublin.o $(SUBDIRS) 
$(SUBDIRS):
	$(MAKE) -C $@

#Install
install: $(INSTALLDIRS)
$(INSTALLDIRS): 
	$(MAKE) -C $(@:install-%=%) install

#Uninstall
uninstall: $(UNINSTALLDIRS)
$(UNINSTALLDIRS):
	$(MAKE) -C $(@:uninstall-%=%) uninstall

#copy the tools into one folder
copy: $(COPYDIRS)
$(COPYDIRS):
	@mkdir -p deb/usr/bin
	@cp gnublin-tools/gnublin-$(@:copy-%=%)/gnublin-$(@:copy-%=%) deb/usr/bin

# make a debian package containing all gnublin-tools
release: gnublin-tools copy
	@# generate .deb
	@mkdir -p deb/DEBIAN

	@# determine installed size of package
	@DEBSIZE=`du -c -k -s deb/usr/bin/ | tail -n 1 | gawk '/[0-9]/ { print $1 }'`

	@# create control file
	@echo "Package: gnublin-tools" > deb/DEBIAN/control
	@echo "Version: $(VERSION)" >> deb/DEBIAN/control
	@echo "Section: devel" >> deb/DEBIAN/control
	@echo "Priority: optional" >> deb/DEBIAN/control
	@echo "Architecture: $(Architecture)" >> deb/DEBIAN/control
	@echo "Essential: no" >> deb/DEBIAN/control
	@echo "Depends: " >> deb/DEBIAN/control
	@echo "Installed-Size: $(DEBSIZE)"  >> deb/DEBIAN/control
	@echo "Maintainer: $(Maintainer)" >> deb/DEBIAN/control
	@echo "Description: Gnublin tools" >> deb/DEBIAN/control

	@# build package
	@dpkg -b deb/ gnublin-tools.deb
#clean
clean: $(CLEANDIRS)
	rm -Rf *.o gnublin.a libgnublin.so.1.0.1
$(CLEANDIRS): 
	$(MAKE) -C $(@:clean-%=%) clean
