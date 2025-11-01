# Local Development Guide

## Prerequisites
- Ruby 3.3 or higher
- Bundler

## Setup

1. Install dependencies:
```bash
bundle install
```

## Local Testing

### Method 1: Using the provided script
```bash
./serve.sh
```

### Method 2: Manual command
```bash
bundle exec jekyll serve --host 0.0.0.0 --livereload
```

The site will be available at: **http://localhost:4000**

The `--livereload` flag enables automatic browser refresh when you make changes.

## Building for Production

To build the site without running a server:
```bash
bundle exec jekyll build
```

The built site will be in the `_site` directory.

## Common Issues

### Theme not found
If you get a "jekyll-theme-chirpy theme could not be found" error:
1. Make sure you've run `bundle install`
2. The GitHub Actions workflow should now work correctly with the updated configuration

### Port already in use
If port 4000 is already in use, you can specify a different port:
```bash
bundle exec jekyll serve --port 4001
```

## Deployment

The site automatically deploys to GitHub Pages when you push to the `master` branch via GitHub Actions.

The workflow:
1. Checks out the code
2. Sets up Ruby and installs dependencies
3. Builds the Jekyll site
4. Deploys to GitHub Pages

You can view the deployment status in the "Actions" tab of your GitHub repository.
