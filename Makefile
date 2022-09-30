
ROOT_DIR             := $(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
DOCKER_ARGS          := run --rm --mount type=bind,source="$(ROOT_DIR)",target=/documents
DOCKER_IMAGE         := asciidoctor/docker-asciidoctor
DOCKER                = podman $(DOCKER_ARGS)

REV                  := "HEAD"
REVDATE              := "$(shell git show -s --format=%cd --date=iso $(REV))"
REVNUMBER            := $(shell (echo `git rev-parse --abbrev-ref $(REV)`  `git show -s --format=%h $(REV)`; git tag --points-at $(REV)) | tail -1)

MKDIR                 = mkdir
MKDIR_P               = $(MKDIR) -p

RM_RF                 = rm -rf

# Compute info about current version
ifneq ($(shell git status --porcelain),)
	REVNUMBER    :="$(REVNUMBER) (local changes)"
else
	REVNUMBER    :="$(REVNUMBER)"
endif

# Input / source content

ADOC_SRCDIR          := src

BOOK_ADOC            := $(ADOC_SRCDIR)/main.adoc

# Output / generated content

SUPPORTED_FORMATS    := html
DEFAULT_FORMATS      ?= html

BUILDDIR             := build

HTML_BUILDDIR        := $(BUILDDIR)/html

HTML_BOOK            := $(HTML_BUILDDIR)/index.html

# Asciidoctor

ASCIIDOC_ARGS        := --failure-level=WARNING -a revnumber=${REVNUMBER} -a revdate=${REVDATE}

ASCIIDOC_INPUT       := $(BOOK_ADOC)

.PHONY: all
all: $(DEFAULT_FORMATS)

.PHONY: clean
clean:
	-$(RM_RF) $(BUILDDIR)

# Management of our docker image, for cases when we add new things and
# want to trigger a one-time docker pull.  Add an explanation for the
# update to .docker-image-requirements.
.docker-image-current: .docker-image-requirements
	docker pull $(DOCKER_IMAGE)
	docker image inspect -f "{{.RepoDigests}}" $(DOCKER_IMAGE):latest > .docker-image-current

# Phony 'force' target to force the creation of all book and chapter
# output in lieu of a comprehensive list of input dependencies.

.PHONY: force
force:

# Build Directories

$(BUILDDIR) $(DOCBOOK_BUILDDIR) $(DOCX_BUILDDIR) $(HTML_BUILDDIR) $(PDF_BUILDDIR) $(BUILDDIR)/diff $(BUILDDIR)/diff/pdf:
	$(MKDIR_P) $(@)

# Docbook Format

# Force building the book or chapters due to a lack of exhaustive dependencies.

# HTML Format

# Force building the book or chapters due to a lack of exhaustive dependencies.

$(HTML_BOOK): force

#$(HTML_BOOK): .docker-image-current

$(HTML_BOOK): $(ASCIIDOC_INPUT) | $(HTML_BUILDDIR)
	$(DOCKER) $(DOCKER_IMAGE) asciidoctor ${ASCIIDOC_ARGS} -r asciidoctor-diagram -o $(@) $(<)

html html-book: $(HTML_BOOK)

# Some targets to make all the books

html-all: html

# Diff Outputs

help:
	@echo "This makefile supports the following targets:"
	@echo ""
	@echo "  all"
	@echo "    Generate the specification in book form in all default formats"
	@echo "    (default: '$(DEFAULT_FORMATS)')."
	@echo ""
	@echo "  docbook docbook-book"
	@echo "    Generate the specification in book form in the DocBook format."
	@echo ""
	@echo "  docbook-chapters"
	@echo "    Generate the specification in individual chapter form in the DocBook format."
	@echo ""
	@echo "  docx docx-book"
	@echo "    Generate the specification in book form in the Microsoft Word Open XML"
	@echo "    format."
	@echo ""
	@echo "  docx-chapters"
	@echo "    Generate the specification in individual chapter form in the Microsoft Word"
	@echo "    Open XML format."
	@echo ""
	@echo "  html html-book"
	@echo "    Generate the specification in book form in the HTML format."
	@echo ""
	@echo "  pdf pdf-book"
	@echo "    Generate the specification in book form in the PDF format."
	@echo ""
	@echo "The following make variables may be set to influence the behavior of the"
	@echo "generated content:"
	@echo ""
	@echo "   DEFAULT_FORMATS"
	@echo "     The default formats to generate the specfication in (default:"
	@echo "     '$(DEFAULT_FORMATS)'). The value of 'DEFAULT_FORMATS' may be one or more of the"
	@echo "     supported formats: '$(SUPPORTED_FORMATS)'."
	@echo ""
	@echo "   ENABLE_PARAGRAPH_NUMBERING"
	@echo "     If this variable is set, paragraphs will be numbered for easy ballot"
	@echo "     cross-referencing in PDF and HTML output. Note that this option is NOT"
	@echo "     compatible with pdf-diff since it causes a final diff that is too large"
	@echo "     and too long (hours) to compute."
