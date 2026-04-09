TESTS_DIR=tests

.PHONY: test test-file

test:
	@for f in $(TESTS_DIR)/test_*.lua; do \
		echo "=== $$f ==="; \
		nvim --headless --noplugin -u tests/minimal_init.lua \
			+"lua MiniTest.run_file('$$f')" \
			+"qa!" || exit 1; \
	done

test-file:
	@nvim --headless --noplugin -u tests/minimal_init.lua \
		+"lua MiniTest.run_file('$(FILE)')" \
		+"qa!" || exit 1
