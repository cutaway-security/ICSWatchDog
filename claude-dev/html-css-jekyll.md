# HTML / CSS / Jekyll Code Standards

## HTML

### Structure

- Use semantic HTML5 elements: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`
- Include alt text on all images
- All pages must have consistent navigation (back to index, section-to-section)
- All external links open in new tab: `target="_blank" rel="noopener"`

### Code Blocks

- AI prompts and code samples must be formatted as copyable blocks
- Use `<pre><code class="language-[lang]">` or fenced code blocks
- Include copy-to-clipboard functionality where students need to use the content

### Accessibility

- Maintain logical heading hierarchy (h1 > h2 > h3, no skipping)
- Ensure sufficient color contrast for readability
- High-contrast styling for projector readability in workshop contexts

## CSS

- Mobile-first responsive design
- Test at 768px and 375px breakpoints minimum
- Use CSS custom properties (variables) for colors, spacing, and typography
- No CSS frameworks unless explicitly approved
- Clean, professional appearance prioritizing readability

## Jekyll / GitHub Pages

### Templating

- Use Kramdown (GitHub Pages default) for Markdown processing
- Use Liquid for templating logic
- Leverage `_layouts/` for page templates and `_includes/` for reusable components

### Markdown

- Use ATX-style headers (`#` not underline style)
- One sentence per line where practical (aids diffs and review)
- Fenced code blocks with language identifiers
- Tables use pipe syntax with alignment

### Build Verification

- `bundle exec jekyll build` must complete without errors
- Verify HTML output in `_site/` renders correctly
- Check that all internal links resolve to valid pages
- Verify template variables populate correctly

## File Naming

- All filenames: lowercase with hyphens (no underscores, no spaces)
- Page files: descriptive names matching URL structure
- Asset files: organized in `css/`, `js/`, `img/` directories
