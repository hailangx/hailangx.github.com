# Haiyang Xu's Personal Blog

A Jekyll-based technical blog powered by the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) theme, hosted on GitHub Pages. Features posts about computer vision, algorithms, and technology.

## 🎨 Theme

This site uses the **Jekyll Chirpy Theme** - a minimal, responsive, and feature-rich Jekyll theme for technical writing.

## 🔧 Setup & Local Development

### Prerequisites

- Ruby 3.3 or higher
- Bundler gem

### Installation

1. **Install Ruby and Bundler** (if not already installed):
   ```bash
   # On macOS/Linux
   gem install bundler
   
   # On Windows, install Ruby via RubyInstaller
   # Then run: gem install bundler
   ```

2. **Clone the repository**:
   ```bash
   git clone https://github.com/hailangx/hailangx.github.com.git
   cd hailangx.github.com
   ```

3. **Install dependencies**:
   ```bash
   bundle install
   ```

4. **Run locally**:
   ```bash
   bundle exec jekyll serve
   ```
   
   The site will be available at `http://localhost:4000`

## 🚀 Deployment

The site automatically deploys via GitHub Actions when you push to the main/master branch. 

### GitHub Pages Configuration

1. Go to **Repository Settings → Pages**
2. Set **Source** to "GitHub Actions"
3. The workflow will automatically build and deploy the site

## 📝 Writing Posts

Create new posts in the `_posts` directory with the naming convention:
```
YYYY-MM-DD-title-of-post.md
```

Example front matter:
```yaml
---
layout: post
title: "Your Post Title"
description: "Brief description"
categories: [Category1, Category2]
tags: [tag1, tag2]
---
```

## ⚙️ Configuration

Key settings in `_config.yml`:

- **Site Info**: Update `title`, `tagline`, and `description`
- **URL**: Set to `https://haiyangxu.github.io`
- **Author**: Update social links and contact information
- **Analytics**: Configure Google Analytics ID
- **Comments**: Configure Disqus shortname

## ✨ Features

- 📱 Fully responsive design with dark/light mode
- 🎯 Hierarchical categories and trending tags
- 📊 Mathematical expressions and Mermaid diagrams support
- 💬 Disqus comments integration
- 📈 Google Analytics support
- 🔍 SEO optimization
- 📄 Automatic sitemap generation
- 📰 RSS feed
- 🔎 Syntax highlighting with Rouge
- 📑 Table of contents in posts

## 📁 Directory Structure

```
.
├── _config.yml          # Site configuration
├── _data/              # Data files (contact, share)
├── _posts/             # Blog posts
├── _tabs/              # Navigation tabs (About, Archives, Categories, Tags)
├── assets/             # Images and other assets
└── .github/workflows/  # GitHub Actions workflows
```

---

**Blog URL**: https://haiyangxu.github.io  
**Theme**: [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy)  
**Last Updated**: October 2025 - Migrated to Chirpy theme
