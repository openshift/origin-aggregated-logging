EXTRA_DIST = _static _templates conf.py \
    index.rst introduction.rst installation.rst \
    configuration.rst sample_rulebase.rst internals.rst \
    contacts.rst changes.rst libraryapi.rst \
    lognormalizer.rst license.rst graph.png

htmldir = $(docdir)
built_html = _build/html

#html_DATA = $(built_html)/index.html

# Makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    = -n -W -c $(srcdir)
#SPHINXBUILD   = sphinx-build
PAPER         =
BUILDDIR      = _build

# Internal variables.
ALLSPHINXOPTS   = -d $(BUILDDIR)/doctrees $(SPHINXOPTS) $(srcdir)

.PHONY: clean-local html-local man-local all-local dist-hook install-data-hook

dist-hook:
	find $(distdir)/ -name .gitignore | xargs rm -f

clean-local:
	-rm -rf $(BUILDDIR)/*

html-local:
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(BUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)/html."

man-local:
	$(SPHINXBUILD) -b man $(ALLSPHINXOPTS) $(BUILDDIR)/man
	@echo
	@echo "Build finished. The manual pages are in $(BUILDDIR)/man."

all-local: html-local

install-data-hook:
	find $(built_html) -type f -printf "%P\n" | \
	while read file; do \
	    echo " $(INSTALL_DATA) -D $(built_html)/$$file '$(DESTDIR)$(htmldir)/$$file'"; \
	    $(INSTALL_DATA) -D $(built_html)/$$file "$(DESTDIR)$(htmldir)/$$file" || exit $$?; \
	done

uninstall-local:
	-rm -rf "$(DESTDIR)$(htmldir)"
