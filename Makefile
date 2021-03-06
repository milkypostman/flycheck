EMACS = emacs
EMACSFLAGS =
CARTON = carton
VAGRANT = vagrant
INSTALL-INFO = install-info
VERSION = $(shell EMACS=$(EMACS) $(CARTON) version)

SRCS = flycheck.el
OBJECTS = $(SRCS:.el=.elc)

DOC_SRCS = doc/api.texi \
	doc/changes.texi \
	doc/checkers.texi \
	doc/contribution.texi \
	doc/credits.texi \
	doc/extending.texi \
	doc/fdl-1.3.texi \
	doc/flycheck.texi \
	doc/introduction.texi \
	doc/usage.texi

PACKAGE_SRCS = $(SRCS) \
	flycheck-pkg.el \
	doc/flycheck.info doc/dir flycheck.el
PACKAGE = flycheck-$(VERSION).tar

.PHONY: build
build : $(OBJECTS)

.PHONY: deps
deps :
	EMACS=$(EMACS) $(CARTON) install
	EMACS=$(EMACS) $(CARTON) update

.PHONY: clean-deps
clean-deps :
	rm -rf elpa # Clean packages installed for development

.PHONY: doc
doc : doc/dir

.PHONY: clean-doc
clean-doc :
	rm -f doc/flycheck.info doc/dir

.PHONY: test
test : build
	EMACS=$(EMACS) $(CARTON) exec $(EMACS) \
		-Q --no-site-lisp $(EMACSFLAGS) --script \
		tests/flycheck-testrunner.el


.PHONY: virtual-test
virtual-test :
	$(VAGRANT) up
	$(VAGRANT) ssh -c "make -C /vagrant EMACS=$(EMACS) clean test"

.PHONY: package
package : $(PACKAGE)

.PHONY: pkg-file
pkg-file : flycheck-pkg.el

$(PACKAGE) : $(PACKAGE_SRCS)
	rm -rf flycheck-$(VERSION)
	mkdir -p flycheck-$(VERSION)
	cp -f $(PACKAGE_SRCS) flycheck-$(VERSION)
	tar cf $(PACKAGE) flycheck-$(VERSION)
	rm -rf flycheck-$(VERSION)

.PHONY: clean
clean :
	rm -f $(OBJECTS)
	rm -rf $(PACKAGE)

%.elc : %.el
	EMACS=$(EMACS) $(CARTON) exec $(EMACS) \
		--no-site-file --no-site-lisp --batch $(EMACSFLAGS) \
		-f batch-byte-compile $<

flycheck-pkg.el : Carton
	EMACS=$(EMACS) $(CARTON) package

doc/dir : doc/flycheck.info
	$(INSTALL-INFO) doc/flycheck.info doc/dir

doc/flycheck.info : $(DOC_SRCS)
