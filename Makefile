PRS_TARGETS = presentation.pdf
NTS_TARGETS = presentation_notes.pdf
HDO_TARGETS = presentation_handout.pdf
PRS_BNDL_TARGETS = $(patsubst %.pdf,%.tar.Z,$(PRS_TARGETS))
PRS_OUT_TARGETS = $(patsubst %.pdf,%.out,$(PRS_TARGETS))
HDO_CMP_TARGETS = $(patsubst %.pdf,%-compressed.pdf,$(HDO_TARGETS))
PDF_TARGETS = $(PRS_TARGETS) $(NTS_TARGETS) $(HDO_TARGETS) $(HDO_CMP_TARGETS)
TEX_SRCS := $(patsubst %pdf,%tex,$(PRS_TARGETS))
TEX_XTRA_SRCS := $(wildcard bit-*.tex)
BIB_SRCS := $(wildcard *.bib)
IMG_SRCS := $(wildcard img/*)
OTH_SRCS := $(wildcard *.tex) $(wildcard *.sty) $(wildcard *.bst) $(wildcard img/*)

TEX = lualatex -file-line-error -interaction=errorstopmode
LATEXMK_CE_OPTS = '$$cleanup_includes_cusdep_generated=1;'

.PHONY: all init extras compressed bundle install clean realclean

.DEFAULT_GOAL := $(PRS_TARGETS)

all: init $(PRS_TARGETS) extras bundle

init:

$(PRS_TARGETS): %.pdf:%.tex $(TEX_XTRA_SRCS) $(BIB_SRCS) $(OTH_SRCS)
	for AUX in $(wildcard *.aux); do echo $${AUX}; [ -s $${AUX} ] || rm $${AUX}; done
	latexmk -pdf -pdflatex="$(TEX)" -bibtex -use-make $<

$(NTS_TARGETS): %.pdf:%.tex $(PRS_TARGETS)
	latexmk -pdf -pdflatex="$(TEX)" -nobibtex -f -use-make $< || true

$(HDO_TARGETS): %.pdf:%.tex $(PRS_TARGETS)
	latexmk -pdf -pdflatex="$(TEX)" -bibtex -use-make $< || true

$(HDO_CMP_TARGETS): $(HDO_TARGETS)
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$(basename $<)-compressed.pdf $< || true

$(PRS_OUT_TARGETS):
	if [ ! -e "$(PRS_OUT_TARGETS)" ]; then $(MAKE) realclean; fi
	$(MAKE) $(PRS_TARGETS)

$(PRS_BNDL_TARGETS): $(PRS_OUT_TARGETS) $(PRS_TARGETS)
	bundledoc --texfile=$(basename $<).tex --keepdirs --include=Makefile --include="*.bib" --include="*.tex" --config=bundledoc.cfg $(basename $<).dep

extras: $(NTS_TARGETS) $(HDO_TARGETS) $(HDO_CMP_TARGETS)

bundle: $(PRS_BNDL_TARGETS)

install: $(PRS_TARGETS) $(HDO_CMP_TARGETS) $(PRS_BNDL_TARGETS)
	install -v -m 644 $(PRS_TARGETS) $(HDO_CMP_TARGETS) $(PRS_BNDL_TARGETS) ..

clean:
	latexmk -c -bibtex -e $(LATEXMK_CE_OPTS)
	rm $(patsubst %pdf,%nav,$(PDF_TARGETS)) || true
	rm $(patsubst %pdf,%snm,$(PDF_TARGETS)) || true
	rm $(patsubst %pdf,%vrb,$(PDF_TARGETS)) || true
	rm $(patsubst %pdf,%dep,$(PDF_TARGETS)) || true
	rm $(PRS_BNDL_TARGETS) || true
	rm $(HDO_CMP_TARGETS) || true

cleanall: clean
	latexmk -C -bibtex -e $(LATEXMK_CE_OPTS)
