#LUA =
#CFLAGS =
#LIBFLAG =
#LUALIB =
#LUA_INCDIR =
#LUA_LIBDIR =

ifdef PKGCONFIG_BINDIR
PKGCONFIG = $(PKGCONFIG_BINDIR)/pkg-config
else
PKGCONFIG = pkg-config
endif

VIPS_CFLAGS  = `$(PKGCONFIG) --cflags vips`
VIPS_LDFLAGS = `$(PKGCONFIG) --libs   vips`

LIB_EXT = .so

# Reserved for internal use:
_CFLAGS =
_LDFLAGS =


.PHONY: build clean lint lint-lua lint-js lint-sh test install gh-pages

build: .gitignore doc live-share/resource/static live-share/image_processor$(LIB_EXT)

live-share/resource/static: live-share/resource/static-src
	cd $< && npm install
	mkdir -p $@
	cd $< && npm run build

%$(LIB_EXT): _CFLAGS += -I$(LUA_INCDIR)
%$(LIB_EXT): _LDFLAGS += -L$(LUA_LIBDIR)
ifdef LUALIB
%$(LIB_EXT): _LDFLAGS += -l$(LUALIB)
endif
live-share/image_processor$(LIB_EXT): _CFLAGS += $(VIPS_CFLAGS)
live-share/image_processor$(LIB_EXT): _LDFLAGS += $(VIPS_LDFLAGS)
%$(LIB_EXT): %.c
	$(CC) $(_CFLAGS) $(CFLAGS) $(_LDFLAGS) $(LIBFLAG) $(LDFLAGS) -o $@ $^

doc:
	mkdir $@

doc/lua: live-share config.ld doc
	ldoc --dir $@ $<

doc/web: live-share apidoc.json doc
	apidoc --input $< --output $@

gh-pages: doc/lua doc/web
	tools/update-gh-pages $<

clean:
	git clean -fdX

lint: lint-lua lint-js lint-sh

lint-lua: live-share
	luacheck $^

lint-js: live-share/resource/static-src
	cd $< && npm run lint

lint-sh: tools/show-test-coverage tools/update-gh-pages
	checkbashisms --extra $^

test:
	busted '--lua=$(LUA)' $@

install:
	cp --parents -t $(INSTALL_LIBDIR) $(shell find live-share -name '*$(LIB_EXT)')
	cp --parents -t $(INSTALL_LUADIR) $(shell find live-share -name '*.lua')
	cp --parents -t $(INSTALL_LUADIR) live-share/schema.sql
	cp --parents -r -t $(INSTALL_LUADIR) live-share/resource/static
