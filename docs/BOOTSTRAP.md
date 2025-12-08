# Bootstrap Integration Guide

## Overview

This project uses **Bootstrap 5.3+** for UI styling and responsive design. The integration uses a CDN + Importmap approach to avoid Node.js build complexity while maintaining theme customization capabilities.

## Architecture

### How Bootstrap is Loaded

- **CSS**: Loaded via CDN `<link>` tag in `app/views/layouts/application.html.erb`
- **JavaScript**: Loaded via importmap from `config/importmap.rb`
  - Bootstrap ES modules
  - Popper.js (required for tooltips, popovers, dropdowns)
- **Theme Customization**: CSS Custom Properties in `app/assets/stylesheets/application.css`

### Why This Approach?

✅ **No Node.js required** - Uses Rails' native asset pipeline (Propshaft + importmap)
✅ **Simple deployment** - No npm install, no build step
✅ **Customizable theme** - Brand colors and spacing via CSS variables
✅ **Turbo compatible** - Bootstrap JS works with Hotwire/Turbo
✅ **Fast CDN delivery** - Browser caching, global distribution

### Integration Points

| Component | File | Purpose |
|-----------|------|---------|
| Bootstrap CSS | `app/views/layouts/application.html.erb` | CDN link tag in `<head>` |
| Bootstrap JS | `config/importmap.rb` | Pin Bootstrap + Popper.js |
| JS Import | `app/javascript/application.js` | Import Bootstrap, Turbo integration |
| Theme Variables | `app/assets/stylesheets/application.css` | Custom colors, spacing, border radius |

## Custom Theme

The application uses a custom gardening/seedling theme with earth tones:

### Color Palette

```css
--bs-primary: #2d6a4f;     /* Forest green - primary actions */
--bs-secondary: #52b788;   /* Light green - secondary elements */
--bs-success: #40916c;     /* Success green */
--bs-info: #74c69d;        /* Info light green */
--bs-warning: #f4a261;     /* Warning orange */
--bs-danger: #e76f51;      /* Danger red */
```

### Customization

To modify the theme, edit `/app/assets/stylesheets/application.css`:

```css
:root {
  --bs-primary: #your-color;
  --bs-primary-rgb: r, g, b;
  /* Add other overrides */
}
```

See [Bootstrap's CSS Variables documentation](https://getbootstrap.com/docs/5.3/customize/css-variables/) for all available variables.

## Key Files

### 1. Layout (`app/views/layouts/application.html.erb`)

Defines the global page structure:
- Bootstrap CSS CDN link
- Responsive navbar with mobile hamburger menu
- Container for main content
- Flash message alerts
- Footer

### 2. Forms (`app/views/plants/_form.html.erb`, `app/views/settings/edit.html.erb`)

Bootstrap form components:
- `.form-label` - Styled labels
- `.form-control` - Text inputs, textareas, number fields
- `.form-select` - Dropdown/select menus
- `.form-text` - Helper text below fields
- `.alert.alert-danger` - Error messages

### 3. Tables (`app/views/tasks/index.html.erb`, `app/views/plants/index.html.erb`)

Responsive table styling:
- `.table-responsive` - Horizontal scroll on mobile
- `.table-hover` - Row hover effects
- `.table-striped` - Alternating row colors
- `.badge` - Colored status/type indicators
- `.btn-group` - Grouped action buttons

### 4. Cards (`app/views/plants/show.html.erb`)

Card-based layouts:
- `.card` with `.card-header` and `.card-body`
- Definition lists (`.row` grid for key-value pairs)
- List groups for timeline items
- Responsive 2-column → 1-column layout

## Turbo Integration

Bootstrap JS is integrated with Turbo Drive to ensure components work after navigation:

```javascript
// In app/javascript/application.js
document.addEventListener("turbo:load", () => {
  // Auto-initialize tooltips
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  const tooltipList = [...tooltipTriggerList].map(el => new bootstrap.Tooltip(el))

  // Auto-initialize popovers
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]')
  const popoverList = [...popoverTriggerList].map(el => new bootstrap.Popover(el))
})
```

The `turbo:load` event fires on initial page load and after every Turbo navigation, ensuring Bootstrap components reinitialize properly.

## Bootstrap Components Used

### Navigation
- **Navbar** - Responsive navigation with mobile collapse
- **Nav tabs/links** - Active state highlighting

### Layout
- **Grid system** - Responsive columns (`.container`, `.row`, `.col-*`)
- **Spacing utilities** - Margin/padding (`.m-*`, `.p-*`, `.mb-3`, `.mt-4`)
- **Display utilities** - Flexbox helpers (`.d-flex`, `.justify-content-between`)

### Components
- **Alerts** - Flash messages, info boxes (`.alert`, `.alert-dismissible`)
- **Badges** - Status indicators (`.badge`, `.bg-success`)
- **Buttons** - Styled actions (`.btn`, `.btn-primary`, `.btn-outline-*`)
- **Cards** - Content containers (`.card`, `.card-header`, `.card-body`)
- **Forms** - Input styling (`.form-control`, `.form-select`, `.form-label`)
- **Tables** - Data tables (`.table`, `.table-hover`, `.table-striped`)

### Interactive (JavaScript)
- **Collapse** - Mobile navbar toggle
- **Tooltips** - Hover hints (requires Popper.js)
- **Popovers** - Click-triggered popups (requires Popper.js)
- **Alerts** - Dismissible messages

## Updating Bootstrap

To update to a newer Bootstrap version:

1. **Check latest version**: Visit https://getbootstrap.com/
2. **Update CSS CDN**: Edit `app/views/layouts/application.html.erb`
   - Update `href` URL to new version
   - Update `integrity` hash (get from Bootstrap CDN page)
3. **Update JS importmap**: Edit `config/importmap.rb`
   - Update Bootstrap pin URL to new version
   - Update Popper.js if needed
4. **Test thoroughly**:
   - Check all interactive components (navbar, forms, tooltips)
   - Verify mobile responsiveness
   - Test Turbo navigation

## Troubleshooting

### Issue: Bootstrap JS not loading

**Symptoms**: `window.bootstrap` is undefined in console

**Solution**:
1. Check browser console for import errors
2. Verify importmap pins are correct in `config/importmap.rb`
3. Ensure `<%= javascript_importmap_tags %>` is in layout `<head>`

### Issue: Tooltips/popovers not working after Turbo navigation

**Symptoms**: Components work on initial load but break after clicking links

**Solution**: Ensure `turbo:load` event listener is in `app/javascript/application.js` (already implemented)

### Issue: Modals leave dark backdrop after closing

**Symptoms**: Modal backdrop persists after Turbo navigation

**Solution**: Add to `app/javascript/application.js`:

```javascript
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll('.modal-backdrop').forEach(el => el.remove())
})
```

### Issue: Custom colors not applying

**Symptoms**: Bootstrap uses default blue instead of custom green

**Solution**:
1. Verify CSS variables are in `:root` block in `application.css`
2. Ensure `application.css` loads **after** Bootstrap CSS in layout
3. Check browser DevTools → Computed styles to see if variables are set
4. Clear browser cache (Ctrl+Shift+R / Cmd+Shift+R)

### Issue: Content Security Policy blocking CDN

**Symptoms**: Bootstrap CSS/JS blocked, errors in console

**Solution**: Update `config/initializers/content_security_policy.rb`:

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.style_src :self, :https, "https://cdn.jsdelivr.net"
    policy.script_src :self, :https, "https://cdn.jsdelivr.net"
  end
end
```

## Mobile Responsiveness

Bootstrap's mobile-first approach means:

### Breakpoints
- **< 576px (xs)**: Mobile phones - navbar collapses, single-column layout
- **576-768px (sm)**: Large phones/small tablets
- **768-992px (md)**: Tablets - navbar expands, some multi-column layouts
- **992-1200px (lg)**: Desktops
- **> 1200px (xl)**: Large desktops

### Responsive Features
- **Navbar**: Collapses to hamburger menu on mobile
- **Tables**: Horizontal scroll via `.table-responsive`
- **Forms**: Single-column on mobile, can expand on larger screens
- **Grid**: Columns stack vertically on mobile (`.col-md-8` → full width on mobile)
- **Buttons**: Full-width on mobile (`.d-grid`), inline on desktop (`.d-md-flex`)

### Testing
Use Chrome DevTools device emulation:
1. Open DevTools (F12)
2. Click Toggle Device Toolbar (Ctrl+Shift+M / Cmd+Shift+M)
3. Test at different viewport sizes

## Accessibility

Bootstrap includes built-in accessibility features:

- **ARIA labels**: Navigation toggles, form inputs
- **Semantic HTML**: `<nav>`, `<header>`, `<footer>`, `<main>`
- **Keyboard navigation**: All interactive elements tabbable
- **Screen reader support**: Hidden labels, role attributes
- **Focus indicators**: Visible focus states on buttons/links
- **Color contrast**: Meets WCAG AA standards (verify custom colors)

## Performance

### CDN Benefits
- **Browser caching**: Users may already have Bootstrap cached
- **Global distribution**: Fast delivery from nearby servers
- **No build time**: Faster deployments

### File Sizes (minified + gzipped)
- Bootstrap CSS: ~27KB
- Bootstrap JS: ~12KB
- Popper.js: ~7KB
- **Total**: ~46KB (very reasonable for a full UI framework)

## Alternative Approaches Considered

### Why NOT cssbundling-rails?

We chose CDN + importmap over cssbundling-rails because:

❌ **Node.js required** - Adds build complexity
❌ **npm dependencies** - 100MB+ node_modules
❌ **Deployment complexity** - Need Node.js in production
❌ **Build step** - Slower development and deployment

✅ **Our approach** works better for this project's simplicity goals

However, if you later need:
- Advanced SASS features (mixins, functions, loops)
- Tree-shaking (removing unused Bootstrap components)
- Full control over every Bootstrap variable

Then consider migrating to cssbundling-rails.

## Resources

- [Bootstrap Documentation](https://getbootstrap.com/docs/5.3/)
- [Bootstrap Examples](https://getbootstrap.com/docs/5.3/examples/)
- [Bootstrap Icons](https://icons.getbootstrap.com/) (optional addition)
- [Importmap Rails Guide](https://github.com/rails/importmap-rails)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)

## Future Enhancements

Potential Bootstrap-related improvements:

1. **Add Bootstrap Icons** - Icon library via CDN
2. **Toast notifications** - Replace alerts with toast messages
3. **Offcanvas menu** - Slide-out navigation on mobile
4. **Progress bars** - Visual task completion tracking
5. **Accordion** - Collapsible plant details
6. **Input groups** - Enhanced form fields with icons
7. **Pagination** - For large task/plant lists

## Support

For Bootstrap-specific issues:
- Check this documentation first
- Review [Bootstrap docs](https://getbootstrap.com/docs/5.3/)
- Search [Stack Overflow](https://stackoverflow.com/questions/tagged/bootstrap-5)

For project-specific integration issues:
- Check `app/javascript/application.js` for Turbo integration
- Verify importmap pins in `config/importmap.rb`
- Review view files for proper Bootstrap class usage
