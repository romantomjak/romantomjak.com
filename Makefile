.PHONY: run build clean deploy

run:
	hugo server -D

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
