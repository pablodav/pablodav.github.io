run-docs: ## Run in development mode
	hugo serve -D

site: ## Build the site
	hugo -t hugo-material-docs -d public --gc --minify --cleanDestinationDir
