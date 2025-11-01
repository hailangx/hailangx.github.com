#!/bin/bash
# Local development server script for Jekyll Chirpy theme

echo "Starting Jekyll local development server..."
echo "The site will be available at: http://localhost:4000"
echo "Press Ctrl+C to stop the server"
echo ""

bundle exec jekyll serve --host 0.0.0.0 --livereload --drafts
