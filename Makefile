.PHONY: run init-gh-pages-branch build clean deploy

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
