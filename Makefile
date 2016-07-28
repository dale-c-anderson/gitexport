LOCAL_SCRIPTS = gitexport-deploy.sh
LOCAL_SCRIPTS += gitexport-latest-only.sh
LOCAL_SCRIPTS += gitexport-since-when.sh
LOCAL_SCRIPTS += gitexport-whole-repo.sh

CONFIGS = gitexport.exclusions

LOCAL_BIN_DIR  ?= "$(HOME)/bin"

build:
	@echo There is nothing to configure or build. This is just a collection of shell-scripts.
	@echo Run \'sudo make install\' or \'sudo make uninstall\'.

install: uninstall

	# make sure local bin dir exists
	install -v -m 755 -d "$(LOCAL_BIN_DIR)"

	# install scripts
	$(foreach file,$(LOCAL_SCRIPTS), install -v -m 755 "$(file)" "$(LOCAL_BIN_DIR)";)

	# install exclusions
	test -f "$(LOCAL_BIN_DIR)/gitexport.exclusions" || install -v -m 644 -T gitexport.exclusions.example "$(LOCAL_BIN_DIR)/gitexport.exclusions"

uninstall:

	$(foreach file,$(LOCAL_SCRIPTS), if [ -f "$(LOCAL_BIN_DIR)/$(file)" ]; then rm -fv "$(LOCAL_BIN_DIR)/$(file)"; fi;)
	$(foreach file,$(CONFIGS), if [ -f "$(LOCAL_BIN_DIR)/$(file)" ]; then rm -fv "$(LOCAL_BIN_DIR)/$(file)"; fi;)
