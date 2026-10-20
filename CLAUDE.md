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

Detroit: Become Human (CyberLife UI) look. Tokens are CSS custom properties in `css/index.css`; `index.html` is self-contained and repeats them inline.

- Night-blue background (`--night` #0b1a24), ice-white text (`--ice` #e6f0f6), secondary text (`--frost` #93aabb)
- One accent color: thirium blue (`--thirium` #3cc8ff)
- Fonts: Saira (navigation, labels, headings), Spectral (body text)
- Homepage copy is direct and factual: no metaphors or jokes, and no fact shown twice
- `blog.html`, the `*-wrapped-2025.html` pages, and posts that don't load `js/loadTemplates.js` keep their own inline designs
- Uses Prism.js (CDN) for code syntax highlighting

## Adding Blog Posts

1. Create new HTML file in `blogs/`
2. Use existing posts as template (include header/footer divs, loadTemplates.js)
3. Add entry to `feed.xml` with title, link, description, pubDate, guid
