include config.mk

.PHONY: build clean lint test install gh-pages

build: src/web/dist
	tools/install-lua-deps

GENERATED_FILES += src/web/dist
GENERATED_FILES += src/web/node_modules
src/web/dist:
	cd src/web && npm install
	cd src/web && npm run build

GENERATED_FILES += doc
doc:
	mkdir $@

ifneq ($(LDOC),)
doc/lua: config.ld src/lua/live-share
	'$(LDOC)' --config $< --dir $@
endif

ifneq ($(APIDOC),)
doc/web: src/lua/live-share apidoc.json
	'$(APIDOC)' --input $< --output $@
endif

clean:
	rm -vr $(GENERATED_FILES)

lint:
	'$(LUACHECK)'
	cd src/web && npm run lint

ifneq ($(BUSTED),)
test:
	'$(BUSTED)' '--lua=$(LUA)' $@
endif

install:
	# install src/lua
	# install bin
	#
	# install src/web/dist

gh-pages: doc
	tools/update-gh-pages $<
