server:
	# Run a Jekyll Docker container.
	#
	# - GH uses Jekyll v3.9 (see https://pages.github.com/versions/) but there
	#   is no 3.9 tag on the Docker Hub (see https://hub.docker.com/r/jekyll/jekyll/tags) 
	#   so we use 3.8.
	#
	# - This is quite slow to start-up as it has to install all the Ruby
	#   dependencies from the Gemfile.lock
	docker run --rm \
		--volume="${PWD}:/srv/jekyll" \
		-p 4000:4000 \
		-it jekyll/jekyll:3.8 \
		jekyll serve --incremental

run:
	# Upgrade dependencies
	#
	# See https://github.com/envygeeks/jekyll-docker/blob/master/README.md#updating
	docker run --rm \
		--volume="${PWD}:/srv/jekyll" \
		-it jekyll/jekyll:3.8 \
		bundle update
