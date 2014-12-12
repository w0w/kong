PWD = `pwd`
# Dev environment variables
DEV_DAEMON ?= off
DEV_LUA_LIB ?= lua_package_path \"$(PWD)/src/?.lua\;\;\"\;
DEV_LUA_CODE_CACHE ?= off
DEV_APENODE_CONF ?= $(PWD)/tmp/apenode.dev.yaml
DEV_APENODE_PORT ?= 8000
DEV_APENODE_WEB_PORT ?= 8001

.PHONY: test local global run populate test-web test-all

local:
	@luarocks make apenode-*.rockspec --local

global:
	@sudo luarocks make apenode-*.rockspec

test:
	@busted spec/dao

test-web:
	@sed \
		-e "s/{{DAEMON}}/on/g" \
		-e "s@{{LUA_LIB_PATH}}@$(DEV_LUA_LIB)@g" \
		-e "s/{{LUA_CODE_CACHE}}/on/g" \
		-e "s/{{PORT}}/8000/g" \
		-e "s/{{WEB_PORT}}/8001/g" \
		-e "s@{{APENODE_CONF}}@$(DEV_APENODE_CONF)@g" \
		templates/nginx.conf > tmp/nginx/nginx.conf;

	@cp -R src/apenode/web/static tmp/nginx/
	@cp -R src/apenode/web/admin tmp/nginx/
	@nginx -p ./tmp/nginx -c nginx.conf
	@busted spec/web/
	@nginx -p ./tmp/nginx -c nginx.conf -s stop

test-proxy:
	@sed \
		-e "s/{{DAEMON}}/on/g" \
		-e "s@{{LUA_LIB_PATH}}@$(DEV_LUA_LIB)@g" \
		-e "s/{{LUA_CODE_CACHE}}/on/g" \
		-e "s/{{PORT}}/8000/g" \
		-e "s/{{WEB_PORT}}/8001/g" \
		-e "s@{{APENODE_CONF}}@$(DEV_APENODE_CONF)@g" \
		templates/nginx.conf > tmp/nginx/nginx.conf;

	@cp -R src/apenode/web/static tmp/nginx/
	@cp -R src/apenode/web/admin tmp/nginx/
	@nginx -p ./tmp/nginx -c nginx.conf
	@busted spec/proxy/
	@nginx -p ./tmp/nginx -c nginx.conf -s stop

test-all:
	@echo "Unit tests:"
	@$(MAKE) test
	@echo "\nAPI tests:"
	@$(MAKE) test-web
	@echo "\nProxy tests:"
	@$(MAKE) test-proxy

populate:
	@lua scripts/populate.lua

run:
	@mkdir -p tmp/nginx/logs
	@cp templates/apenode.yaml $(DEV_APENODE_CONF)
	@echo "" > tmp/nginx/logs/error.log
	@echo "" > tmp/nginx/logs/access.log
	@sed \
		-e "s/{{DAEMON}}/$(DEV_DAEMON)/g" \
		-e "s@{{LUA_LIB_PATH}}@$(DEV_LUA_LIB)@g" \
		-e "s/{{LUA_CODE_CACHE}}/$(DEV_LUA_CODE_CACHE)/g" \
		-e "s/{{PORT}}/$(DEV_APENODE_PORT)/g" \
		-e "s/{{WEB_PORT}}/$(DEV_APENODE_WEB_PORT)/g" \
		-e "s@{{APENODE_CONF}}@$(DEV_APENODE_CONF)@g" \
		templates/nginx.conf > tmp/nginx/nginx.conf;

	@cp -R src/apenode/web/static tmp/nginx/
	@cp -R src/apenode/web/admin tmp/nginx/
	@nginx -p ./tmp/nginx -c nginx.conf