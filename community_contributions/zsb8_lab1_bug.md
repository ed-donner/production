# Bug Report: `styles/globals.css` Styles Not Taking Effect

## Problem

The custom styles defined in `styles/globals.css` were not being applied in the project. Specifically, the `.markdown-content` styles (for h1–h6, p, ul, ol, li, strong, em, hr) had no visible effect on the markdown-rendered content in `pages/product.tsx`.

## Root Causes

1. **Missing Tailwind entry point**: The `globals.css` file did not include `@import "tailwindcss"`. In Tailwind CSS v4, this import is required for Tailwind to initialize and process the stylesheet correctly.

2. **`@layer base` behavior**: The custom styles were wrapped in `@layer base`. Without proper Tailwind initialization, this layer directive could be ignored or mishandled by the build pipeline.

3. **Cascade priority**: Tailwind's Preflight (resets) normalizes heading and other element styles. When custom styles are placed in `@layer base`, they may be overridden by Preflight or other base-layer rules depending on cascade order.

## Solution

1. **Add the Tailwind import** at the top of `globals.css`:
   ```css
   @import "tailwindcss";
   ```

2. **Remove the `@layer base` wrapper** and define the `.markdown-content` styles as plain CSS. This ensures:
   - Styles are not dependent on Tailwind's layer system
   - Higher cascade priority so they override Preflight
   - Reliable application regardless of Tailwind initialization

## Files Changed

- `styles/globals.css`: Added `@import "tailwindcss"` and moved `.markdown-content` rules out of `@layer base`.

## Alternative Approach

If using `@tailwindcss/typography`, you can replace the custom `.markdown-content` styles with the built-in `prose` class:

```tsx
<div className="prose prose-gray dark:prose-invert max-w-none text-gray-700 dark:text-gray-300">
  <ReactMarkdown remarkPlugins={[remarkGfm, remarkBreaks]}>{idea}</ReactMarkdown>
</div>
```


# Result 
`styles\globals.css `
```
@import "tailwindcss";

/* Markdown 内容样式 - 使用普通 CSS 确保优先级高于 Preflight */
.markdown-content h1 {
    font-size: 2em;
    font-weight: bold;
    margin: 0.67em 0;
  }
  .markdown-content h2 {
    font-size: 1.5em;
    font-weight: bold;
    margin: 0.83em 0;
  }
  .markdown-content h3 {
    font-size: 1.17em;
    font-weight: bold;
    margin: 1em 0;
  }
  .markdown-content h4 {
    font-size: 1em;
    font-weight: bold;
    margin: 1.33em 0;
  }
  .markdown-content h5 {
    font-size: 0.83em;
    font-weight: bold;
    margin: 1.67em 0;
  }
  .markdown-content h6 {
    font-size: 0.67em;
    font-weight: bold;
    margin: 2.33em 0;
  }
  .markdown-content p {
    margin: 1em 0;
  }
  .markdown-content ul {
    list-style-type: disc;
    padding-left: 2em;
    margin: 1em 0;
  }
  .markdown-content ol {
    list-style-type: decimal;
    padding-left: 2em;
    margin: 1em 0;
  }
  .markdown-content li {
    margin: 0.25em 0;
  }
  .markdown-content strong {
    font-weight: bold;
  }
  .markdown-content em {
    font-style: italic;
  }
.markdown-content hr {
  border: 0;
  border-top: 1px solid #e5e7eb;
  margin: 2em 0;
}
```