#LUA =
#CFLAGS =
#LIBFLAG =
#LUALIB =
#LUA_INCDIR =
#LUA_LIBDIR =
#VIPS_INCDIR =
#VIPS_LIBDIR =
LIB_EXT = .so

.PHONY: build clean lint lint-lua lint-js lint-sh test install gh-pages

build: .gitignore doc live-share/resource/static #live-share/image_processor$(LIB_EXT)

live-share/resource/static: live-share/resource/static-src
	cd $< && npm install
	mkdir -p $@
	cd $< && npm run build

%$(LIB_EXT): CFLAGS += -I$(LUA_INCDIR)
%$(LIB_EXT): LDFLAGS += -L$(LUA_LIBDIR)
ifdef LUALIB
%$(LIB_EXT): LDFLAGS += -l$(LUALIB)
endif
%$(LIB_EXT): %.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(LIBFLAG) -o $@ $^

live-share/image_processor$(LIB_EXT): CFLAGS += -I$(VIPS_INCDIR)
live-share/image_processor$(LIB_EXT): LDFLAGS += -L$(VIPS_LIBDIR) -lvips

doc:
	mkdir $@

doc/lua: live-share config.ld doc
	ldoc --dir $@ $<

doc/web: live-share apidoc.json doc
	apidoc --input $< --output $@

gh-pages: doc/lua doc/web
	tools/update-gh-pages $<

clean:
	git clean -X

lint: lint-lua lint-js lint-sh

lint-lua: live-share
	luacheck $^

lint-js: live-share/resource/static-src
	cd $< && npm run lint

lint-sh: tools/show-test-coverage tools/update-gh-pages
	checkbashisms --extra $^

test:
	busted '--lua=$(LUA)' $@

bla:
	echo $(shell find live-share -name '*$(LIB_EXT)')

blubb:
	find live-share -name '*$(LIB_EXT)'

install:
	#cp --parents -t $(INSTALL_LIBDIR) $(shell find live-share -name '*$(LIB_EXT)')
	cp --parents -t $(INSTALL_LUADIR) $(shell find live-share -name '*.lua')
	cp --parents -t $(INSTALL_LUADIR) live-share/schema.sql
	cp --parents -r -t $(INSTALL_LUADIR) live-share/resource/static
