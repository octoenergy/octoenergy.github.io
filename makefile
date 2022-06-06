server:
	# Run jekyll/jekyll Docker image.
	# - GH uses Jekyll v3.9 (see https://pages.github.com/versions/) but there is no tag for that so we use 3.8.
	# - This is quite slow to start-up as it has to install all the Ruby dependencies from the Gemfile.lock
	docker run --rm \
		--volume="${PWD}:/srv/jekyll" \
		-p 4000:4000 \
		-p 35729:35729 \
		-it jekyll/jekyll:3.8 \
		jekyll serve --livereload

upgrade:
	# Upgrade dependencies
	# See https://github.com/envygeeks/jekyll-docker/blob/master/README.md#updating
	docker run --rm \
		--volume="${PWD}:/srv/jekyll" \
		-it jekyll/jekyll:3.8 \
		bundle update
