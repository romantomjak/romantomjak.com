.PHONY: run init-gh-pages-branch build clean deploy
.DEFAULT_GOAL := help

help:
	@printf "%s\n" "Build targets:"
	@printf "  %-20s - %s\n" "run" "Run http server"
	@printf "  %-20s - %s\n" "init-gh-pages-branch" "Initializes GH pages branch"
	@printf "  %-20s - %s\n" "build" "Generate static website and exit"
	@printf "  %-20s - %s\n" "new-post" "Create a new blog post"
	@printf "  %-20s - %s\n" "clean" "Delete generated files"
	@printf "  %-20s - %s\n" "deploy" "Commit and push to GH pages"

run:
	hugo server -D

# run only when origin/gh-pages does not exist
init-gh-pages-branch:
	git checkout --orphan gh-pages
	git reset --hard
	git commit --allow-empty -m "Initializing gh-pages branch"
	git push upstream gh-pages
	git checkout master

build: clean
	hugo

new-post:
	@echo "usage: hugo new posts/my-post.md"

clean:
	rm -rf public
	mkdir public
	git worktree prune
	rm -rf .git/worktrees/public/
	git worktree add -B gh-pages public origin/gh-pages
	rm -rf public/*

deploy: build
	cd public/ \
	&& git add --all \
	&& git commit -m "Publishing to gh-pages (make deploy)" \
	&& cd ..
	git push origin gh-pages
