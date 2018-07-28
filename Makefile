.PHONY: run build deploy

run:
	hugo server -D

build:
	hugo

deploy:
	rm -rf public
	mkdir public
	git worktree prune
	rm -rf .git/worktrees/public/
	git worktree add -B gh-pages public origin/gh-pages
	rm -rf public/*
	$(build)
	cd public/
	echo "romantomjak.com" > CNAME
	git add --all
	git commit -m "Publishing to gh-pages (make deploy)"
	cd ..
	git push origin gh-pages
