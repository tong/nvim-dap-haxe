HASHLINK_DEBUGGER := hashlink-debugger
VSHAXE            := vshaxe

HASHLINK_DEBUGGER_REPO := https://github.com/vshaxe/hashlink-debugger.git
VSHAXE_REPO            := https://github.com/vshaxe/vshaxe.git

ADAPTER_DIR = adapter

.PHONY: build adapter-eval adapter-hl clean update ensure-repos

all: build

ensure-repos:
	@if [ ! -d "$(HASHLINK_DEBUGGER)" ]; then \
		echo "→ Cloning hashlink-debugger..."; \
		git clone --recurse-submodules $(HASHLINK_DEBUGGER_REPO) $(HASHLINK_DEBUGGER); \
	fi
	@if [ ! -d "$(VSHAXE)" ]; then \
		echo "→ Cloning vshaxe..."; \
		git clone --recurse-submodules $(VSHAXE_REPO) $(VSHAXE); \
	fi

$(VSHAXE)/eval-debugger/bin/index.js: ensure-repos
	cd $(VSHAXE) && \
		npx lix run vshaxe-build -t eval-debugger -- -D no-traces

adapter-eval: $(VSHAXE)/eval-debugger/bin/index.js
	mkdir -p $(ADAPTER_DIR)
	cp $(VSHAXE)/eval-debugger/bin/index.js $(ADAPTER_DIR)/eval.js

$(HASHLINK_DEBUGGER)/adapter.js: ensure-repos
	cd $(HASHLINK_DEBUGGER) && make build

adapter-hl: $(HASHLINK_DEBUGGER)/adapter.js
	mkdir -p $(ADAPTER_DIR)
	npx esbuild $(HASHLINK_DEBUGGER)/adapter.js \
		--bundle \
		--platform=node \
		--external:hldebug-wrapper \
		--external:\*.node \
		--outfile=$(ADAPTER_DIR)/hl.js
	terser $(ADAPTER_DIR)/hl.js -o $(ADAPTER_DIR)/hl.js
	mkdir -p $(ADAPTER_DIR)/node_modules
	rsync -a --prune-empty-dirs \
		--include="package.json" \
		--include="index.js" \
		--include="lib/***" \
		--include="lib/**/*.node" \
		--exclude="*" \
		$(HASHLINK_DEBUGGER)/hldebug-wrapper/ $(ADAPTER_DIR)/node_modules/hldebug/

build: ensure-repos adapter-eval adapter-hl

update:
	@if [ -d "$(HASHLINK_DEBUGGER)" ]; then \
		echo "→ Updating HashLink Debugger..."; \
		cd $(HASHLINK_DEBUGGER) && git pull --recurse-submodules && npm install; \
	fi
	@if [ -d "$(VSHAXE)" ]; then \
		echo "→ Updating vshaxe..."; \
		cd $(VSHAXE) && git pull --recurse-submodules; npm install; \
	fi
	$(MAKE) build

clean:
	rm -rf $(ADAPTER_DIR)

