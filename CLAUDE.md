# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Static HTML portfolio and blog site for Josh Fonseca. Hosted at jfr.dev, GitHub repo: jfonsecarivera/portfoliosite.

## Architecture

- **No build system** - pure static HTML, CSS, and vanilla JavaScript
- **Client-side template loading** - `js/loadTemplates.js` uses Fetch API to inject shared header/footer from `templates/`
- **RSS feed** - `feed.xml` with autodiscovery link injected via loadTemplates.js

## Key Files

- `index.html` - Landing page with project showcase
- `blog.html` - Blog hub
- `project.html` - Projects page
- `js/loadTemplates.js` - Dynamic template loading + RSS autodiscovery
- `templates/header.html`, `templates/footer.html` - Shared components
- `blogs/*.html` - Individual blog posts (33 articles)
- `feed.xml` - RSS feed (manually maintained)
- `css/index.css` - Base stylesheet (many pages also use inline styles)

## Development

No build commands required. Serve files directly with any static server:

```bash
python3 -m http.server 8000
# or
npx serve .
```

## Design System

- Dark theme background (#0a0a0a) with light text (#e0e0e0)
- Accent colors: cyan (#00f3ff), purple (#bd00ff), orange (#ffaa00), green (#10b981)
- Fonts: Inter (headings), Merriweather (body), Fira Code (code)
- Max content width: 900px
- Uses Prism.js (CDN) for code syntax highlighting

## Adding Blog Posts

1. Create new HTML file in `blogs/`
2. Use existing posts as template (include header/footer divs, loadTemplates.js)
3. Add entry to `feed.xml` with title, link, description, pubDate, guid
