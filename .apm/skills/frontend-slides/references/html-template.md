# HTML runtime

Single file. Inline CSS and JS. No npm, no build.

Include in the `<style>` block, in order:

1. The full contents of [viewport-base.css](../viewport-base.css)
2. The full contents of [briefing.css](briefing.css) for the default world, or the committed override tokens/chrome
3. Slide-specific layouts for this deck

Font for the default world:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Barlow:ital,wght@0,400;0,600;0,700;0,800;1,400&display=swap" rel="stylesheet">
<link rel="icon" href="data:,">
```

Put a direction contract in a CSS comment before `:root`:

```css
/*
DIRECTION CONTRACT
THESIS: one sentence the deck has to prove.
OWN-WORLD: navy/orange/cream/green; sharp bands, thick chevrons, numbered spines.
           (replace this line if the operator named another world)
STORY: the sequence of sections.
FIRST VIEWPORT: what the title slide must make unmistakable.
FORM: fixed 1920x1080 briefing; hybrid reading and speaking unless stated.
*/
```

## Skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deck title</title>
    <!-- fonts -->
    <style>
        /* viewport-base.css */
        /* briefing.css or override world */
        /* deck layouts */
    </style>
</head>
<body>
    <button type="button" class="edit-hotzone" aria-label="Toggle edit mode" title="Toggle edit mode"></button>
    <button class="edit-toggle" id="editToggle" title="Edit mode (E)" tabindex="-1">Edit</button>

    <div class="deck-viewport">
        <main class="deck-stage" id="deckStage">
            <section class="slide hero-slide active visible">
                <div class="slash" aria-hidden="true"></div>
                <div class="hero">
                    <div class="hero-top"></div>
                    <h1 class="reveal d2">Title</h1>
                    <p class="lead reveal d3">Stand-alone first sentence.</p>
                </div>
                <div class="slide-index">01 / NN</div>
            </section>

            <section class="slide">
                <div class="head">
                    <div class="title-stack">
                        <div class="section-tag">Section</div>
                        <h1>Slide title</h1>
                    </div>
                </div>
                <div class="content">
                    <p class="lead reveal d1">What this slide must leave behind.</p>
                </div>
                <div class="slide-index">02 / NN</div>
            </section>
        </main>
    </div>

    <nav class="deck-controls" aria-label="Slide controls">
        <button type="button" id="prevBtn">Previous</button>
        <span id="ctrlCount" aria-live="polite" aria-atomic="true">01 / NN</span>
        <button type="button" id="nextBtn">Next</button>
    </nav>

    <script>
        const STORE_KEY = "deck-slug-v1";
        const FILE_NAME = "deck.html";
        /* paste controller below */
    </script>
</body>
</html>
```

Heading order is sequential. Do not jump `h1` to `h3`. One `h1` per slide.

Slide indexes and `#ctrlCount` must match the real count (`01 / 12`, not a leftover).

## Controller

Paste this as the deck script. Do not switch slides with `display: none`.

```javascript
const STORE_KEY = "deck-slug-v1";
const FILE_NAME = "deck.html";

class SlidePresentation {
    constructor() {
        this.slides = Array.from(document.querySelectorAll(".slide"));
        this.currentSlide = 0;
        this.stage = document.getElementById("deckStage");
        this.ctrlCount = document.getElementById("ctrlCount");
        this.wheelLock = false;
        this.setupStageScale();
        this.setupKeyboardNav();
        this.setupTouchNav();
        this.setupWheelNav();
        this.setupButtons();
        this.showSlide(0);
    }

    setupStageScale() {
        const scale = () => {
            const factor = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
            const x = (window.innerWidth - 1920 * factor) / 2;
            const y = (window.innerHeight - 1080 * factor) / 2;
            this.stage.style.transform = `translate(${x}px, ${y}px) scale(${factor})`;
        };
        scale();
        window.addEventListener("resize", scale);
    }

    setupKeyboardNav() {
        document.addEventListener("keydown", (e) => {
            if (e.target.getAttribute("contenteditable")) return;
            if (e.target.closest("button")) return;
            if (["ArrowRight", "ArrowDown", "PageDown", " "].includes(e.key)) {
                e.preventDefault();
                this.next();
            } else if (["ArrowLeft", "ArrowUp", "PageUp"].includes(e.key)) {
                e.preventDefault();
                this.prev();
            } else if (e.key === "Home") {
                e.preventDefault();
                this.showSlide(0);
            } else if (e.key === "End") {
                e.preventDefault();
                this.showSlide(this.slides.length - 1);
            }
        });
    }

    setupTouchNav() {
        let startX = 0;
        this.stage.addEventListener("touchstart", (e) => {
            startX = e.changedTouches[0].screenX;
        }, { passive: true });
        this.stage.addEventListener("touchend", (e) => {
            const dx = e.changedTouches[0].screenX - startX;
            if (Math.abs(dx) < 48) return;
            if (dx < 0) this.next();
            else this.prev();
        }, { passive: true });
    }

    setupWheelNav() {
        window.addEventListener("wheel", (e) => {
            if (document.body.classList.contains("editing")) return;
            if (Math.abs(e.deltaY) < 24) return;
            e.preventDefault();
            if (this.wheelLock) return;
            this.wheelLock = true;
            if (e.deltaY > 0) this.next();
            else this.prev();
            setTimeout(() => { this.wheelLock = false; }, 520);
        }, { passive: false });
    }

    setupButtons() {
        document.getElementById("prevBtn").addEventListener("click", () => this.prev());
        document.getElementById("nextBtn").addEventListener("click", () => this.next());
    }

    next() { this.showSlide(this.currentSlide + 1); }
    prev() { this.showSlide(this.currentSlide - 1); }
    goToSlide(index) { this.showSlide(index); }

    showSlide(index) {
        this.currentSlide = Math.max(0, Math.min(index, this.slides.length - 1));
        this.slides.forEach((slide, i) => {
            slide.classList.toggle("active", i === this.currentSlide);
            slide.classList.toggle("visible", i === this.currentSlide);
        });
        const n = String(this.currentSlide + 1).padStart(2, "0");
        const t = String(this.slides.length).padStart(2, "0");
        this.ctrlCount.textContent = n + " / " + t;
    }
}

class InlineEditor {
    constructor() {
        this.isActive = false;
        this.toggleBtn = document.getElementById("editToggle");
        this.editables = document.querySelectorAll("h1, h2, h3, h4, p, li, .lead, .oid, .actor, .ms-num");
        this.restore();
        this.bindHotzone();
        this.toggleBtn.addEventListener("click", () => this.toggleEditMode());
        document.addEventListener("keydown", (e) => {
            if ((e.key === "e" || e.key === "E") && !e.target.getAttribute("contenteditable") && !e.metaKey && !e.ctrlKey) {
                this.toggleEditMode();
            }
            if ((e.ctrlKey || e.metaKey) && e.key === "s") {
                e.preventDefault();
                this.save();
                this.download();
            }
        });
    }

    bindHotzone() {
        const hotzone = document.querySelector(".edit-hotzone");
        let hideTimeout = null;
        const show = () => {
            clearTimeout(hideTimeout);
            this.toggleBtn.classList.add("show");
            this.toggleBtn.tabIndex = 0;
        };
        const hide = () => {
            hideTimeout = setTimeout(() => {
                if (!this.isActive) {
                    this.toggleBtn.classList.remove("show");
                    this.toggleBtn.tabIndex = -1;
                }
            }, 400);
        };
        hotzone.addEventListener("mouseenter", show);
        hotzone.addEventListener("mouseleave", hide);
        this.toggleBtn.addEventListener("mouseenter", () => clearTimeout(hideTimeout));
        this.toggleBtn.addEventListener("mouseleave", hide);
        hotzone.addEventListener("click", () => this.toggleEditMode());
    }

    toggleEditMode() {
        this.isActive = !this.isActive;
        document.body.classList.toggle("editing", this.isActive);
        this.toggleBtn.classList.toggle("active", this.isActive);
        this.toggleBtn.classList.toggle("show", this.isActive);
        this.toggleBtn.tabIndex = this.isActive ? 0 : -1;
        this.toggleBtn.textContent = this.isActive ? "Editing" : "Edit";
        this.editables.forEach((el) => {
            el.setAttribute("contenteditable", this.isActive ? "true" : "false");
        });
        if (!this.isActive) {
            this.toggleBtn.blur();
            this.save();
        }
    }

    collect() {
        return Array.from(this.editables).map((el) => el.innerHTML);
    }

    save() {
        localStorage.setItem(STORE_KEY, JSON.stringify(this.collect()));
    }

    restore() {
        const raw = localStorage.getItem(STORE_KEY);
        if (!raw) return;
        try {
            const parts = JSON.parse(raw);
            this.editables.forEach((el, i) => {
                if (typeof parts[i] === "string") el.innerHTML = parts[i];
            });
        } catch (err) {
            return;
        }
    }

    download() {
        this.save();
        const blob = new Blob([document.documentElement.outerHTML], { type: "text/html" });
        const a = document.createElement("a");
        a.href = URL.createObjectURL(blob);
        a.download = FILE_NAME;
        a.click();
        URL.revokeObjectURL(a.href);
    }
}

const deck = new SlidePresentation();
const editor = new InlineEditor();
window.deck = deck;
window.presentation = deck;
window.editor = editor;
```

### STORE_KEY

`STORE_KEY` is per-deck localStorage. Bump the version suffix whenever you add, remove, or reorder editable nodes. Otherwise an old edit session overwrites the new copy. Pattern: `<slug>-v<n>`. Include it in any structural check for a maintained deck.

### Editor hotzone

Do not show the edit button with a CSS `~` sibling selector. `pointer-events: none` breaks that hover chain. The JS 400ms delay above is required.

Include the editor unless the operator asks for a locked/export-only file.

## Images

Relative paths. Same directory or `assets/`. If an image is over ~1MB, resize with:

```bash
uv run --with pillow python -c "from PIL import Image; im=Image.open('in.png'); im.thumbnail((1200,1200)); im.save('out.png')"
```

Never overwrite originals.
