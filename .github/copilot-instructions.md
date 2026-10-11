# Copilot instructions for piranna.github.io

## Project shape
- This repository is a Jekyll-based personal site/blog built from Jekyll Now and deployed with GitHub Pages.
- Site-wide behavior lives in `_config.yml`; before changing routing, pagination, tags, Markdown rendering, or Mermaid support, check that file first.
- The rendered site is mostly content-driven: Markdown posts/pages + Liquid layouts/includes + Sass.

## Content structure
- Blog posts live in `_posts/` and use dated filenames like `YYYY-MM-DD-Title.md`.
- Posts typically use YAML front matter with `layout: post`, `lang: en`, `tags`, and sometimes `redirect_from` for URL migrations (see `_posts/2025-09-16-How-to-build-WebRTC-for-Android-in-Ubuntu-25.04.md`).
- Draft articles live in `_drafts/`.
- Standalone pages live in `pages/`; `pages/blog.html` is the paginated blog index, not a Markdown page.
- The homepage is the root `index.html`, with custom inline CSS and a hand-written “Recent Posts” section.

## Layout and styling patterns
- Layout flow is `post/page -> default`: `_layouts/post.html` and `_layouts/page.html` wrap `_layouts/default.html`.
- Shared head/meta/footer fragments live in `_includes/`.
- Global styling is in `style.scss` and `_sass/` partials; prefer editing those for reusable styling.
- Keep homepage-only styling inside `index.html` unless the change should affect the whole site.

## Jekyll-specific conventions
- Preserve `permalink: pretty` behavior from `_config.yml`; links are expected to be directory-style URLs.
- Blog pagination is driven by `jekyll-paginate-v2` config in `_config.yml` and the `paginator` object in `pages/blog.html`.
- Tag autopages are configured in `_config.yml`; be careful when touching tag routing or autopage layout wiring.
- Mermaid diagrams are supported through `jekyll-spaceship`; keep Mermaid content as fenced `mermaid` code blocks in Markdown posts (see `_posts/2026-03-21-Understanding-npm-Lifecycle-Scripts-(Once-and-For-All).md`).
- Redirects are handled through `jekyll-redirect-from`, so prefer front matter redirects over manual HTML redirect pages.

## Editing guidance
- Prefer minimal content edits: this repo is primarily published writing, so avoid reflowing or rephrasing unrelated prose.
- Preserve front matter keys/order unless there is a reason to change them.
- When adding posts, follow the existing filename/front-matter pattern instead of inventing new content types.
- When changing navigation or shared chrome, inspect `_layouts/default.html` first because header/footer links are hard-coded there.
- When changing author/profile information, start with `_config.yml` and only edit templates if the config cannot express the change.

## Build and deployment workflow
- Dependencies are Ruby gems declared in `Gemfile`; GitHub Actions builds with Ruby 3.0.
- Deployment is automated by `.github/workflows/jekyll-gh-pages.yml`, which runs `bundle exec jekyll build` on pushes to `main` and deploys the generated `_site` to GitHub Pages.
- Another workflow, `.github/workflows/main.yml`, runs `piranna/jekyll-social@master` on every push, so publishing-related metadata in posts can have automation impact.
- For local verification, use Bundler-aware commands such as `bundle install` and `bundle exec jekyll serve` / `bundle exec jekyll build`.

## What not to assume
- There is no conventional application test suite here; validation is mainly “does Jekyll build?” and “does the generated page structure still match existing URLs/layouts?”.
- This is not a generic theme package: several files are directly customized for the owner’s personal branding, navigation, and long-form technical writing.

<!-- mermaid-ai-skills:start -->
## Mermaid Diagrams

When the user asks to create, edit, or visualize a diagram, follow the
instructions in `.github/instructions/mermaid.instructions.md`.
<!-- mermaid-ai-skills:end -->
