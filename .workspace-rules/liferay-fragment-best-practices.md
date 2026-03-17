# Liferay Fragment Development Best Practices

This guide provides the core architectural and design principles for building high-quality Liferay Fragments. Use these rules to ensure consistency, performance, and a premium user experience.

## 1. Directory Structure

Every fragment must reside in its own folder within a collection:
`fragments/[collection-name]/[fragment-name]/`

Internal folder structure:
- `fragment.json`: Metadata and file mapping.
- `index.html`: Semantic HTML structure (FreeMarker).
- `index.css`: Component-specific styling.
- `index.js`: Interactive logic.
- `configuration.json`: User-adjustable settings (background colors, toggles).
- `assets/`: (Optional) Local images or icons.

## 2. The Liferay Way (Framework Rules)

- **Editable Content**: Use `data-lfr-editable-id` and `data-lfr-editable-type="text"` for all text. **Do not** create configuration fields for text that can be edited directly in the page editor.
- **SVGs & Icons**: Never place `<svg>` or `<i>` icon tags inside an element with `data-lfr-editable-id`. If an icon must be inside a button, place the editable text in a separate `<span>` or move the SVG after the editable tag to prevent it from being overwritten by user edits.
- **Auto-Isolated Scoping**: 
    - **JS**: Use the globally provided `fragmentElement` variable. Never manually query the root element using `document.getElementById` or `${fragmentNamespace}`.
    - **HTML**: Do not manually add the fragment namespace ID to the root element; Liferay handles this.
- **Assets**: Reference local assets using `${fragmentCapsule.getAssetURL('filename.ext')}`.
- **FreeMarker**: Use FreeMarker tags `[#if ...]` and `[/#if]` for conditional rendering based on configuration values.

## 3. Design Aesthetics

- **Premium Feel**: Avoid browser defaults. Use curated color palettes, soft gradients (e.g., `linear-gradient(135deg, #f0f7ff, #fff5f0)`), and modern typography (Inter, Roboto).
- **Micro-interactions**: Implement smooth CSS transitions (0.2s - 0.3s) for hovers, button clicks, and state changes.
- **Shadows & Borders**: Use subtle borders (`1px solid #e9ecef`) and soft box-shadows (`0 4px 12px rgba(0,0,0,0.05)`) instead of heavy lines.

## 4. Component Patterns

- **Sidebar/Drawers**:
    - Use `position: fixed` with a high `z-index`.
    - Animate using `right: -100%` to `right: 0` or `opacity/visibility`.
    - Implement a `cart-overlay` backdrop to focus the user.
- **Segmented Lists**:
    - Use `display: flex` with `overflow-x: auto` for tab-style navigation.
    - Use `CustomEvent` on the `window` object to communicate between fragments (e.g., `productCategoryChange`).
- **Cards**:
    - Use a container layout with a header (icon), body (name/description), and footer (action button).
    - Add subtle patterns or icons to corners to give an enterprise "discovery" feel.

## 5. Metadata (`fragment.json`)

Always include explicit paths to all files to ensure successful import:
```json
{
  "configurationPath": "configuration.json",
  "jsPath": "index.js",
  "htmlPath": "index.html",
  "cssPath": "index.css",
  "name": "Component Name",
  "type": "component"
}
```

## 6. API & Security

- **Authentication & CSRF**: When making `fetch` calls to Liferay Headless APIs, you MUST include the CSRF token in the headers.
- **Liferay.authToken**: The token is stored in the browser's global variable `Liferay.authToken`.
- **Implementation Example**:
    ```javascript
    fetch('/o/headless-demo/v1.0/object', {
        headers: {
            'x-csrf-token': Liferay.authToken
        }
    });
    ```
- **URL Parameters**: Retrieve context from the URL using `new URLSearchParams(window.location.search)`.

## 7. Configuration Fields (`configuration.json`)

- **Field Types**: Use standard Liferay field types for fragment configuration.
    - **Color**: Use `"type": "colorPicker"` (camelCase) to provide a color selection interface for users.
    - **Toggle**: Use `"type": "checkbox"` for simple boolean switches.
    - **Select**: Use `"type": "select"` for multiple choice options.
- **Default Values**: Always provide sensible default values to ensure the fragment looks good immediately after being dropped on a page.
- **Naming**: Use descriptive internal names (e.g., `backgroundColor`) and user-friendly labels.
