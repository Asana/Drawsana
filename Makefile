.PHONY: docs publish-docs

docs:
	jazzy -c jazzy.yaml


publish-docs: docs
	ghp-import .docs \
		--no-jekyll \
		--push \
		--force \
		--remote origin \
		--branch gh-pages

