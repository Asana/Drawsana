.PHONY: docs publish-docs

docs:
	jazzy


publish-docs: docs
	ghp-import .docs \
		--no-jekyll \
		--push \
		--force \
		--remote upstream \
		--branch gh-pages

