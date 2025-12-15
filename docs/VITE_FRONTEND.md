# Vite Frontend Architecture

## Overview

Seedling Scheduler uses **Vite 5.4** as its modern frontend build tool, replacing the traditional Rails asset pipeline approach. This provides fast hot module replacement (HMR), modern JavaScript/CSS bundling, and npm package management while maintaining seamless Rails integration.

**Key Benefits:**
- ⚡ Lightning-fast hot module replacement during development
- 📦 Modern npm package ecosystem (Bootstrap, FullCalendar, Stimulus)
- 🔧 Simple configuration with sensible defaults
- 🚀 Optimized production builds with automatic code splitting
- 🎯 TypeScript support out of the box

## Quick Start

### Prerequisites
- **Node.js 20.18.0+** (check with `node -v`)
- **npm 10.8+** (check with `npm -v`)

### Development Commands

```bash
# Start Rails + Vite together (recommended)
bin/dev

# Or start separately:
# Terminal 1
bin/rails server

# Terminal 2
bin/vite dev
```

### Production Build

```bash
# Compile assets for production
bin/vite build

# Assets output to public/vite/assets/
```

---

## Architecture

### Vite's Role in the Stack

```
┌─────────────────────────────────────────┐
│           Browser                        │
│  ┌────────────────────────────────────┐ │
│  │  HTML (Rails ERB views)            │ │
│  │  ├── CSS (from Vite)              │ │
│  │  └── JavaScript (from Vite)       │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    ▲
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼────────┐    ┌─────────▼────────┐
│  Rails Server  │    │   Vite Dev Server │
│  (Port 3000)   │    │   (Port 3036)     │
│                │    │                   │
│  - ERB views   │    │  - Hot reload     │
│  - Controllers │    │  - Bundle JS/CSS  │
│  - Models      │    │  - Transform TS   │
│  - Helpers     │    │  - Process assets │
└────────────────┘    └───────────────────┘
```

**Development Flow:**
1. Rails renders views with `<%= vite_javascript_tag %>` helper
2. Helper generates `<script>` tags pointing to Vite dev server (port 3036)
3. Vite serves JavaScript with HMR injected
4. Changes to JS/CSS instantly reflected without page reload

**Production Flow:**
1. `bin/vite build` compiles and fingerprints all assets
2. Assets written to `public/vite/assets/` with unique hashes
3. Manifest file (`public/vite/manifest.json`) maps logical to physical filenames
4. Rails helpers read manifest and generate production asset paths
5. Assets served directly by web server (Nginx/Apache) or Rails in development

---

## Directory Structure

```
app/frontend/
├── controllers/           # Stimulus controllers
│   ├── calendar_controller.js
│   ├── notification_controller.js
│   ├── task-modal_controller.js
│   └── index.js          # Auto-registers all controllers
├── entrypoints/          # Vite entry points (must use vite_*_tag helpers)
│   └── application.js    # Main entry - imports everything
├── lib/                  # Shared utilities and libraries
│   └── task_colors.js    # Task type color definitions
└── stylesheets/          # CSS files
    └── application.css   # Main stylesheet with Bootstrap overrides
```

### Key Concepts

**Entrypoints:**
- Files in `app/frontend/entrypoints/` are Vite entry points
- Each entrypoint can be loaded via `vite_javascript_tag` helper
- Main entry: `application.js` (loaded in `app/views/layouts/application.html.erb`)

**Controllers:**
- Stimulus controllers live in `app/frontend/controllers/`
- Auto-registered via `registerControllers()` function in `index.js`
- Follow naming convention: `hyphenated-name_controller.js`

**Libraries:**
- Shared utilities in `app/frontend/lib/`
- Can be imported anywhere: `import { TASK_COLORS } from '../lib/task_colors'`

---

## Configuration Files

### vite.config.ts

```typescript
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
})
```

**What it does:**
- `RubyPlugin()`: Integrates Vite with Rails
  - Auto-detects entry points in `app/frontend/entrypoints/`
  - Generates manifest for Rails asset helpers
  - Configures dev server to work with Rails

### package.json

```json
{
  "name": "seedling-scheduler",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  },
  "dependencies": {
    "@fullcalendar/core": "^6.1.15",
    "@fullcalendar/daygrid": "^6.1.15",
    "@fullcalendar/interaction": "^6.1.15",
    "@fullcalendar/multimonth": "^6.1.15",
    "@fullcalendar/bootstrap5": "^6.1.15",
    "@hotwired/stimulus": "^3.2.2",
    "@hotwired/turbo-rails": "^8.0.10",
    "bootstrap": "^5.3.3",
    "@popperjs/core": "^2.11.8"
  },
  "devDependencies": {
    "vite": "^5.4.21",
    "vite-plugin-ruby": "^5.1.1"
  }
}
```

**Key Points:**
- `"type": "module"`: Enables ES modules (import/export)
- Dependencies: Production packages (Bootstrap, FullCalendar, Stimulus)
- DevDependencies: Build tools only (Vite, plugin)

### Procfile.dev

```
vite: bin/vite dev
web: bin/rails server
```

Used by `bin/dev` to run both servers simultaneously via Foreman.

### config/vite.json (auto-generated)

Generated by `vite-plugin-ruby`. Contains Rails integration settings. **Do not edit manually.**

---

## Main Entry Point: application.js

**Location:** `app/frontend/entrypoints/application.js`

```javascript
// Import Turbo and Stimulus
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Import Bootstrap
import * as bootstrap from "bootstrap"

// Import controllers
import { registerControllers } from "../controllers"

// Import styles
import "../stylesheets/application.css"

// Initialize Stimulus
const application = Application.start()
application.debug = false
window.Stimulus = application

// Register all controllers
registerControllers(application)

// Make Bootstrap available globally
window.bootstrap = bootstrap

// Bootstrap auto-initialization
document.addEventListener("turbo:load", () => {
  // Initialize tooltips
  const tooltips = [...document.querySelectorAll('[data-bs-toggle="tooltip"]')]
  tooltips.forEach(el => new bootstrap.Tooltip(el))

  // Initialize popovers
  const popovers = [...document.querySelectorAll('[data-bs-toggle="popover"]')]
  popovers.forEach(el => new bootstrap.Popover(el))
})
```

**What happens:**
1. Imports Turbo Drive for fast page navigation
2. Imports and starts Stimulus framework
3. Imports Bootstrap (CSS + JS) from npm packages
4. Registers all Stimulus controllers
5. Imports custom CSS with Bootstrap theme overrides
6. Sets up Bootstrap components to reinitialize on Turbo navigation

---

## Bootstrap Integration

### How Bootstrap is Loaded

**Previous Approach (DEPRECATED):**
- ❌ Bootstrap CSS via CDN `<link>` tag
- ❌ Bootstrap JS via importmap
- ❌ No build step

**Current Approach (Vite + npm):**
- ✅ Bootstrap installed via npm: `npm install bootstrap`
- ✅ CSS bundled by Vite (imported in `application.js`)
- ✅ JavaScript bundled by Vite
- ✅ Customizable via `app/frontend/stylesheets/application.css`

### Bootstrap CSS Customization

**File:** `app/frontend/stylesheets/application.css`

```css
/* Import Bootstrap first */
@import 'bootstrap/dist/css/bootstrap.min.css';

/* Override Bootstrap variables with custom theme */
:root {
  /* Seedling/gardening theme colors */
  --bs-primary: #2d6a4f;       /* Forest green */
  --bs-primary-rgb: 45, 106, 79;
  --bs-secondary: #52b788;     /* Light green */
  --bs-secondary-rgb: 82, 183, 136;
  --bs-success: #40916c;
  --bs-success-rgb: 64, 145, 108;
  --bs-info: #74c69d;
  --bs-info-rgb: 116, 198, 157;
  --bs-warning: #f4a261;
  --bs-warning-rgb: 244, 162, 97;
  --bs-danger: #e76f51;
  --bs-danger-rgb: 231, 111, 81;
}

/* Add custom styles below */
```

**Why CSS Variables:**
- Bootstrap 5.3+ uses CSS custom properties
- Override colors without Sass compilation
- Changes apply immediately
- Works with Vite's HMR

### Bootstrap JavaScript

Bootstrap is imported and made globally available:

```javascript
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap
```

**Usage in views:**
- Modals: `data-bs-toggle="modal" data-bs-target="#taskModal"`
- Dropdowns: `data-bs-toggle="dropdown"`
- Tooltips: Auto-initialized on `turbo:load`
- Popovers: Auto-initialized on `turbo:load`

**Manual usage:**
```javascript
// In Stimulus controller or inline script
const modal = new bootstrap.Modal(document.getElementById('myModal'))
modal.show()
```

---

## Adding New npm Packages

### Installation

```bash
# Install package
npm install package-name

# Example: Add date-fns utility library
npm install date-fns
```

### Import in JavaScript

**Option 1: Import in entry point (application.js)**
```javascript
import { format } from 'date-fns'
```

**Option 2: Import in Stimulus controller**
```javascript
// app/frontend/controllers/my_controller.js
import { Controller } from "@hotwired/stimulus"
import { format } from 'date-fns'

export default class extends Controller {
  connect() {
    console.log(format(new Date(), 'yyyy-MM-dd'))
  }
}
```

**Option 3: Import in utility library**
```javascript
// app/frontend/lib/date_helpers.js
import { format, parseISO } from 'date-fns'

export function formatTaskDate(dateString) {
  return format(parseISO(dateString), 'MMM d, yyyy')
}
```

### Import Styles from npm Packages

```javascript
// In application.js
import 'package-name/dist/styles.css'

// Example: FullCalendar styles
import '@fullcalendar/core/main.css'
import '@fullcalendar/daygrid/main.css'
```

---

## Development Workflow

### Starting Development Server

**Recommended: Use bin/dev**
```bash
bin/dev
```

This starts both Rails (port 3000) and Vite (port 3036) via Foreman.

**Manual start (for debugging):**
```bash
# Terminal 1: Vite dev server
bin/vite dev
# Output: VITE v5.4.21  ready in X ms
#         ➜  Local: http://localhost:3036/

# Terminal 2: Rails server
bin/rails server
# Output: => Booting Puma
#         => Rails 8.1.1 application starting...
```

### Hot Module Replacement (HMR)

**What is HMR:**
- Edit JavaScript or CSS files
- Changes instantly reflected in browser
- **No page reload required**
- Component state preserved

**Example workflow:**
1. Edit `app/frontend/controllers/calendar_controller.js`
2. Save file
3. Browser updates instantly (no refresh)
4. Calendar state preserved (date selection, view mode)

**HMR works for:**
- ✅ JavaScript files
- ✅ CSS files
- ✅ Imported assets (images, fonts)

**Full reload required for:**
- ❌ Rails views (`.html.erb` files)
- ❌ Rails controllers/models
- ❌ Configuration files

### Debugging

**Check Vite is running:**
```bash
curl http://localhost:3036
# Should return Vite dev server page
```

**Common issues:**

**Issue: "Failed to fetch dynamically imported module"**
- Cause: Vite dev server not running
- Fix: Start `bin/vite dev` or `bin/dev`

**Issue: "Port 3036 already in use"**
- Cause: Previous Vite process still running
- Fix: `pkill -f vite` or `lsof -ti:3036 | xargs kill`

**Issue: Changes not reflecting**
- Cause: Browser cache
- Fix: Hard refresh (Ctrl+Shift+R / Cmd+Shift+R)

**Check Vite logs:**
```bash
# Vite shows all file changes
# Example output:
# 9:15:23 AM [vite] hmr update /app/frontend/controllers/calendar_controller.js
```

---

## Production Builds

### Building Assets

```bash
# Compile and optimize all assets
bin/vite build
```

**What happens:**
1. Vite bundles all JavaScript and CSS
2. Minifies code (removes whitespace, shortens variable names)
3. Tree-shakes unused code (removes unused imports)
4. Generates fingerprinted filenames: `application-abc123.js`
5. Outputs to `public/vite/assets/`
6. Creates manifest: `public/vite/manifest.json`

**Example output:**
```
public/vite/
├── manifest.json
└── assets/
    ├── application-e3b0c442.js       # Main bundle
    ├── application-b5c2a6e1.css      # Styles
    ├── calendar_controller-f4a5b9c8.js  # Code-split chunk
    └── vendor-d41d8cd9.js            # Third-party libraries
```

### Code Splitting

Vite automatically splits code into chunks:
- **Entry chunks:** Your entry points (application.js)
- **Vendor chunks:** Third-party libraries (Bootstrap, FullCalendar)
- **Dynamic chunks:** Lazy-loaded modules

**Benefits:**
- Faster initial page load (browser downloads less code)
- Better caching (vendor code changes less often)
- Parallel downloads (browser fetches chunks simultaneously)

### Asset Fingerprinting

Each build generates unique filenames based on content hash:
- `application-abc123.js` → Content hash: `abc123`
- If content changes, hash changes → New filename
- Old files can be safely cached by browsers
- Rails helpers automatically use correct filename from manifest

### Deployment

**Before deploy:**
```bash
# 1. Build assets
bin/vite build

# 2. Verify build succeeded
ls -la public/vite/assets/

# 3. Commit built assets (if not using CI/CD)
git add public/vite
git commit -m "Build assets for production"
```

**On server:**
- Assets in `public/vite/assets/` served directly by web server (Nginx/Apache)
- No Node.js required in production (assets are pre-built)
- Rails helpers (`vite_javascript_tag`) read from manifest

**CI/CD pipeline:**
```yaml
# Example: .github/workflows/deploy.yml
- name: Setup Node
  uses: actions/setup-node@v3
  with:
    node-version: '20'

- name: Install dependencies
  run: npm install

- name: Build assets
  run: bin/vite build

- name: Deploy
  run: ./deploy.sh
```

---

## Rails View Helpers

### Loading JavaScript

**In layout file:**
```erb
<%# app/views/layouts/application.html.erb %>
<%= vite_client_tag %>
<%= vite_javascript_tag 'application', "data-turbo-track": "reload" %>
```

**What each helper does:**

`vite_client_tag`:
- Development: Loads Vite client for HMR
- Production: No output (not needed)

`vite_javascript_tag 'application'`:
- Development: `<script src="http://localhost:3036/app/frontend/entrypoints/application.js" type="module">`
- Production: `<script src="/vite/assets/application-abc123.js" type="module">`
- Reads from manifest in production

**Options:**
```erb
<%= vite_javascript_tag 'application',
      "data-turbo-track": "reload",  # Reload on asset change
      async: true,                    # Load asynchronously
      defer: true                     # Defer execution
%>
```

### Loading CSS

CSS is automatically loaded when imported in JavaScript:

```javascript
// app/frontend/entrypoints/application.js
import "../stylesheets/application.css"
```

**Manual CSS tag (rarely needed):**
```erb
<%= vite_stylesheet_tag 'application' %>
```

### TypeScript Entry Points

Vite supports TypeScript out of the box:

```erb
<%# If application.js was application.ts %>
<%= vite_typescript_tag 'application' %>
```

### Loading Images/Assets

**In JavaScript:**
```javascript
import logoUrl from '../images/logo.png'
const img = document.createElement('img')
img.src = logoUrl
```

**In CSS:**
```css
.hero {
  background-image: url('../images/hero.jpg');
}
```

Vite automatically:
- Optimizes images
- Generates fingerprinted filenames
- Updates paths in production builds

---

## File Organization Best Practices

### Stimulus Controllers

**Naming convention:**
- File: `my-feature_controller.js` (hyphens, ending in `_controller.js`)
- Class: `export default class extends Controller`
- Usage: `data-controller="my-feature"`

**Example:**
```javascript
// app/frontend/controllers/task-modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "dateInput"]

  connect() {
    console.log("Task modal controller connected")
  }

  submit(event) {
    event.preventDefault()
    // Handle form submission
  }
}
```

### Utility Libraries

**Create shared utilities in `app/frontend/lib/`:**

```javascript
// app/frontend/lib/api_client.js
export async function fetchTasks(startDate, endDate) {
  const response = await fetch(`/tasks.json?start=${startDate}&end=${endDate}`)
  if (!response.ok) throw new Error('Failed to fetch tasks')
  return response.json()
}

export async function createTask(taskData) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content
  const response = await fetch('/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({ task: taskData })
  })
  return response.json()
}
```

**Import in controllers:**
```javascript
import { fetchTasks, createTask } from '../lib/api_client'
```

### Stylesheets

**Main stylesheet:** `app/frontend/stylesheets/application.css`

**Organize styles:**
```css
/* 1. Import external dependencies */
@import 'bootstrap/dist/css/bootstrap.min.css';

/* 2. Define CSS variables (theme overrides) */
:root {
  --bs-primary: #2d6a4f;
}

/* 3. Global styles */
body {
  font-family: system-ui, sans-serif;
}

/* 4. Component-specific styles */
.calendar-container {
  padding: 1rem;
}
```

**Multiple stylesheets (optional):**
```javascript
// Import additional stylesheets
import '../stylesheets/calendar.css'
import '../stylesheets/forms.css'
```

---

## TypeScript Support

Vite has built-in TypeScript support (no configuration needed).

### Using TypeScript

**Rename files:**
- `application.js` → `application.ts`
- `calendar_controller.js` → `calendar_controller.ts`

**Add types:**
```typescript
// app/frontend/controllers/calendar_controller.ts
import { Controller } from "@hotwired/stimulus"
import { Calendar, CalendarOptions } from '@fullcalendar/core'

export default class extends Controller {
  declare calendar: Calendar
  declare calendarTarget: HTMLElement

  static targets = ["calendar"]

  connect(): void {
    this.initializeCalendar()
  }

  private initializeCalendar(): void {
    const options: CalendarOptions = {
      initialView: 'dayGridMonth',
      // ...
    }
    this.calendar = new Calendar(this.calendarTarget, options)
    this.calendar.render()
  }
}
```

**tsconfig.json (optional):**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "preserve"
  },
  "include": ["app/frontend/**/*"]
}
```

---

## Performance Optimization

### Code Splitting

Split large dependencies into separate chunks:

```javascript
// Lazy load FullCalendar only on calendar page
if (document.querySelector('[data-controller="calendar"]')) {
  import('../controllers/calendar_controller').then(module => {
    // Controller auto-registers
  })
}
```

### Tree Shaking

Vite automatically removes unused code:

```javascript
// Only imports used functions (not entire library)
import { format } from 'date-fns'  // ✅ Efficient

// Avoid importing everything
import * as dateFns from 'date-fns'  // ❌ Less efficient
```

### Bundle Analysis

Analyze bundle size:

```bash
# Add to package.json scripts:
"analyze": "vite build --mode analyze"

# Run analysis
npm run analyze
```

### Preloading Critical Assets

```erb
<%# Preload critical JavaScript %>
<%= vite_javascript_tag 'application', preload: true %>
```

---

## Troubleshooting

### Common Issues

**1. "Cannot find module 'bootstrap'"**
```bash
# Solution: Install dependencies
npm install
```

**2. Vite dev server not starting**
```bash
# Check if port 3036 is in use
lsof -ti:3036

# Kill process
lsof -ti:3036 | xargs kill

# Restart Vite
bin/vite dev
```

**3. Assets not loading in production**
```bash
# Rebuild assets
bin/vite build

# Check manifest exists
cat public/vite/manifest.json

# Verify file permissions
ls -la public/vite/assets/
```

**4. HMR not working**
- Hard refresh browser (Ctrl+Shift+R)
- Check Vite terminal for errors
- Verify `vite_client_tag` is in layout
- Check browser console for connection errors

**5. "ReferenceError: bootstrap is not defined"**
- Verify `import * as bootstrap from "bootstrap"` in application.js
- Check `window.bootstrap = bootstrap` is set
- Ensure application.js is loaded before inline scripts

### Debugging Tips

**Enable Vite debug mode:**
```bash
DEBUG=vite:* bin/vite dev
```

**Check Rails asset helpers:**
```erb
<%# In Rails console or view %>
<%= debug Vite.instance.manifest %>
```

**Inspect network requests:**
1. Open DevTools → Network tab
2. Filter by "JS" or "CSS"
3. Check if assets load from localhost:3036 (dev) or /vite/assets/ (prod)

---

## Migrating from Webpacker/Sprockets

### Key Differences

| Aspect | Webpacker/Sprockets | Vite |
|--------|---------------------|------|
| Build tool | Webpack | Vite (Rollup) |
| Config | `config/webpack/` | `vite.config.ts` |
| Entry points | `app/javascript/packs/` | `app/frontend/entrypoints/` |
| Dev server | `bin/webpack-dev-server` | `bin/vite dev` |
| Build | `bin/webpack` | `bin/vite build` |
| Assets | `public/packs/` | `public/vite/` |
| Helpers | `javascript_pack_tag` | `vite_javascript_tag` |

### Migration Steps

1. **Install Vite:**
```bash
bundle add vite_rails
bin/rails vite:install
```

2. **Move files:**
```bash
mv app/javascript/ app/frontend/
mv app/frontend/packs/ app/frontend/entrypoints/
```

3. **Update imports:**
```javascript
// Old: import from 'application'
// New: import from '../path/to/file'
```

4. **Update views:**
```erb
<%# Old %>
<%= javascript_pack_tag 'application' %>

<%# New %>
<%= vite_client_tag %>
<%= vite_javascript_tag 'application' %>
```

5. **Remove Webpacker:**
```bash
bundle remove webpacker
rm -rf node_modules
npm install
```

---

## Resources

### Official Documentation
- [Vite Documentation](https://vitejs.dev/)
- [vite-plugin-ruby Documentation](https://vite-ruby.netlify.app/)
- [Vite Rails Guide](https://vite-ruby.netlify.app/guide/rails.html)

### Community Resources
- [Vite GitHub](https://github.com/vitejs/vite)
- [vite_rails gem](https://github.com/ElMassimo/vite_ruby)

### Related Project Docs
- [Stimulus Controllers Guide](STIMULUS_CONTROLLERS.md)
- [Project Overview](../PROJECT_OVERVIEW.md)
- [JSON API Reference](JSON_API.md)

---

## Summary

Vite provides a modern, fast frontend build experience for Seedling Scheduler:

- **Development:** Lightning-fast HMR, instant updates, modern tooling
- **Production:** Optimized bundles, automatic code splitting, fingerprinted assets
- **Integration:** Seamless Rails integration via `vite-plugin-ruby`
- **Ecosystem:** Access to entire npm ecosystem (Bootstrap, FullCalendar, etc.)

The architecture is simple: Vite bundles your frontend code, Rails serves your views, and the two integrate seamlessly via asset helpers and a manifest file.
