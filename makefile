run:
	bundle exec jekyll server --incremental


# This might create some garbage 
docker-run:
	docker run -it --rm  --volume="${PWD}:/srv/jekyll" -p 4000:4000 -e JEKYLL_UID=$$(id -u) \
		jekyll/jekyll:latest \
		bash -c "jekyll build; bundle exec jekyll server --host 0.0.0.0 --incremental"

