# Design System Strategy: Atmospheric Clarity

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Ethereal Engine."** 

This system rejects the "flat and boxy" enterprise standard in favor of an immersive, atmospheric experience. It treats the interface not as a series of static containers, but as a dynamic environment of light and air. By leveraging the interplay between deep sapphire tones and translucent frosted surfaces, we create a UI that feels both grounded in precision and uplifting in spirit.

We move beyond "template-driven" design by utilizing intentional asymmetry, overlapping "aura" elements, and a radical commitment to glassmorphism. The layout should feel like a premium editorial spread—high-contrast typography paired with vast amounts of "breathing room" to ensure the vibrant blue palette never feels overwhelming.

---

## 2. Colors & Surface Architecture

The palette is built on a foundation of "Azure Vitality." It prioritizes high-value whites and deep, intelligent blues, punctuated by electric accent sparks.

### Color Tokens
*   **Primary (Deep Sapphire):** `#0058bb` — Used for core structural presence and high-priority states.
*   **Primary Container (Sky Blue):** `#6c9fff` — Ideal for large interactive surfaces.
*   **Secondary (Teal Azure):** `#006287` — Supporting brand elements.
*   **Tertiary (Clear Lime):** `#006a26` — Used sparingly for vibrant highlights (success states, new features).
*   **Surface Lowest (Pure White):** `#ffffff` — The base for the most elevated cards.
*   **Surface (Cool Sky White):** `#f2f7ff` — The default background state.

### The "No-Line" Rule
Sectioning must never be achieved via 1px solid borders. Boundaries are defined by the **Tonal Shift**:
*   Use `surface-container-low` (`#ebf1fa`) next to a `surface` background to define regions.
*   Transitioning from `primary` to `primary-container` gradients creates a "soulful" depth that flat color cannot replicate.

### Signature Textures: Glass & Aura
*   **Glassmorphism:** Floating panels must use semi-transparent surface colors with a `backdrop-filter: blur(20px)`. 
*   **The Ghost Border:** A 1px border is allowed *only* on glass elements, using `white` at 20-40% opacity to catch "specular highlights."
*   **Aura Backgrounds:** Solid color backgrounds are prohibited. Every screen must feature a mesh gradient or "aura blobs" blending `surface-bright`, `primary-fixed`, and subtle hints of `tertiary-fixed`.

---

## 3. Typography: Editorial Authority

We use **Plus Jakarta Sans** for its clean, modern, and slightly rounded geometric structure. It bridges the gap between professional software and high-end lifestyle branding.

*   **Display (Large Scale):** Use `display-lg` (3.5rem) for hero statements. Tighten letter-spacing slightly (-0.02em) to create a "locked-in" premium feel.
*   **Headlines:** Use `headline-md` (1.75rem) in `on-surface`. These should sit with ample leading to feel approachable yet authoritative.
*   **Body:** `body-lg` (1rem) is the workhorse. Ensure it never exceeds 65 characters per line to maintain an editorial flow.
*   **Labels:** Use `label-md` (0.75rem) in `primary` or `on-surface-variant` for metadata.

The hierarchy is driven by extreme contrast—placing a very large `display` header near a small, high-contrast `label` creates a sophisticated, asymmetrical tension.

---

## 4. Elevation & Depth: Tonal Layering

Traditional drop shadows are replaced by **Ambient Light** and **Tonal Stacking**.

*   **The Layering Principle:** Depth is achieved by "stacking" container tiers. Place a `surface-container-lowest` card on a `surface-container-low` background. This creates a soft, natural lift without the "muddy" feel of dark shadows.
*   **Ambient Shadows:** When a floating effect is required (e.g., a primary CTA), use a shadow tinted with `primary-dim` at 8% opacity with a large blur (32px+). Avoid neutral grays.
*   **Soft Glows:** High-priority interactive elements (like the Mac download button in the reference) should feature a subtle outer glow using the `primary-fixed-dim` token to simulate self-illumination.
*   **Backdrop Blur:** Glass elements must always blur the "aura blobs" beneath them, ensuring readability while maintaining the "Serene" atmospheric vibe.

---

## 5. Components

### Buttons
*   **Primary:** A gradient transition from `primary` to `primary-dim`. Roundedness: `full`.
*   **Secondary (Glass):** Semi-transparent `surface` with a 1px white "Ghost Border" and `backdrop-blur`.
*   **Interaction:** On hover, primary buttons should exhibit a "Soft Glow" (shadow-spread increase) rather than just a color change.

### Cards & Lists
*   **No Dividers:** Prohibit the use of 1px lines to separate list items. Use the **Spacing Scale** (Step 3 or 4) or alternating tonal shifts between `surface-container-low` and `surface-container-lowest`.
*   **Nesting:** Inner content within a card should sit on a slightly different surface tier to denote hierarchy.

### Input Fields
*   **Styling:** Fields use `surface-container-lowest` with a subtle `outline-variant` Ghost Border (10% opacity).
*   **States:** On focus, the border transitions to `primary` with a soft 4px `primary-container` outer glow.

### Companion Character Integration
Characters must be rendered with "Bright & Uplifting" lighting. Ensure the character casts a soft, blue-tinted ambient shadow onto the UI surfaces, making it feel like a physical part of the digital environment.

---

## 6. Do's and Don'ts

### Do:
*   **DO** use white space as a structural element. 
*   **DO** overlap elements (e.g., a glass card partially covering an "aura blob") to create depth.
*   **DO** use `tertiary-fixed` (Lime) for micro-interactions to provide a "spark" of energy.
*   **DO** ensure all iconography is "Line-Art" style with a consistent 2px stroke weight.

### Don't:
*   **DON'T** use solid `#000000` or muddy browns. If you need a dark tone, use `on-primary-container`.
*   **DON'T** use sharp corners. Always stick to the **Roundedness Scale** (Default: `1rem`).
*   **DON'T** use standard 1px gray borders. If a container isn't visible through tonal shifts or glass effects, re-evaluate the layout.
*   **DON'T** clutter the mesh gradients. Keep the "aura" movement slow and the colors soft.