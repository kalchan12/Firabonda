# Design System: Fira Bonda

## 1. Design direction

Modern, **Gen Z** style: clean, bold, playful but not childish. Dark blue is the primary identity. There is a full light mode as well.

Keywords: rounded, spacious, confident numbers, smooth motion.

## 2. Theme modes

- Dark and Light modes toggled via a clean, modern switch. Default: **Dark**.
- Selection is saved to local preferences and restored on launch. Router instance is preserved across theme switches to prevent unwanted re-navigation.

## 3. Color tokens

| Token | Dark | Light |
|-------|------|-------|
| background | `#0B1020` | `#F6F8FC` |
| surface | `#121A33` | `#FFFFFF` |
| surfaceVariant | `#1A2547` | `#EAEFFA` |
| primary (electric blue) | `#3D6BFF` | `#2F5BFF` |
| onPrimary | `#FFFFFF` | `#FFFFFF` |
| textPrimary | `#F2F5FF` | `#0B1020` |
| textMuted | `#8A96B8` | `#5B6788` |
| profit (green) | `#2ECC8F` | `#14A56E` |
| loss / spent (red) | `#FF5C7A` | `#E0405E` |
| warning (amber) | `#FFB84D` | `#E59A1F` |
| border | `#232F55` | `#D9E0F2` |

Define all colors as theme tokens in one file. Never hardcode colors inside widgets.

## 4. Typography

- Modern bundled fonts (offline first): **Sora** for headings, screen titles, and big money numbers; **Inter** for body text and labels.
- Scale: Display 34/bold (big money numbers), Title 22/bold, Heading 18/semibold, Body 15/regular, Label 12/medium (muted).
- Money values always use tabular figures via `FontFeature.tabularFigures()`, so numbers and prices align vertically.

## 5. Shape, spacing, elevation

- Corner radius: cards 24, buttons 16, chips 999 (pill), bottom sheets 28 top corners.
- Spacing scale: 4, 8, 12, 16, 20, 24, 32.
- Screen padding: 20.
- Touch targets: minimum 52dp on all primary action buttons, inputs, and touchable cards.
- Prefer subtle borders and soft shadows over heavy shadows. Light gradients allowed on hero cards.
- Glass/blur effect only for the floating nav bar and speed-dial overlay backdrop, never behind long text.

## 6. Navigation

Floating bottom dock with 4 destinations and a prominent 68-72dp raised circular center button:

1. Home (dashboard)
2. Purchases
3. **+ Batch Purchase** (center, raised 20dp, accent blue glow, cutout notch) -> opens Batch purchase directly with zero delay (Fix Plan V2.1 Task 3).
4. Sales
5. More

## 7. Core screens

1. **Dashboard**: Unified elevated container canvas, period selector (Today / Yesterday / Week / Month / All / Custom), collapsible Today Shift Card (`_TodayShiftBanner`) with active shift vs all today toggle and automatic transition on close, Net Profit hero tile with status badge, 2x2 grid (Sold, Cost of sold, Bought, Expenses), "Paid with credit" card (credit sales amount & transaction count), unified Target Achievement & Payment Methods card, recent sales in period with credit badges, and expandable "More analytics & stock" accordion with synchronized period dropdown, stock value, low stock alerts, best sellers, and profit trend curve chart.
2. **Purchases list**: Multi-view layout switcher (Card, Grid, Row) with persistent user preference, grouped by date, search bar, modern dropdown filter bar (Categories, Stock status: All/In stock/Low stock/Sold out, Suppliers), lot total target vs remaining target indicator, each card shows category icon, color dot, quantity, unit cost, stock left, quantity-scaled target sell & expected profit with overflow-proof layout ensuring the "Sell" button is always visible and tappable, and interactive photo count badge (`📷 X photos`) that opens a swipeable gallery viewer dialog.
3. **Add / edit purchase**: category chips, color chips, quantity stepper with +1/+5/+10 quick chips, unit cost with last price hint, optional planned selling price with live aggregate revenue and profit scaling preview, compact Photo & Gallery picker allowing 1 image for quantity = 1 and up to quantity images for quantity > 1 with swipe viewer dialog.
4. **Batch purchase**: existing supplier dropdown (with quick "+ New supplier" modal), streamlined per-item purchase price plan (removed total bundle mode), preset Mixed color (`#8E8E93`), optional planned selling price with responsive per-item live profit card, optional item photos and batch notes.
5. **Sales screen**: Multi-view layout switcher (Card, Grid, Row) with persistent user preference, modern scrollable layout, summary banner (Total revenue, Total profit, Items sold, Credit owed), responsive 3-tier sales cards with payment badges (Cash, Bank, Telebirr, Credit • owes ETB X), and modern dropdown filter bar (Cloth type, Days, Payment method).
6. **Simple sell sheet**: 3 clean inputs: category/color/stock header, quantity stepper with quick chips (1, 2, 3, 5, All), planned selling price prefill, live result card (+ETB, Loss, % of target), "Not paid" credit toggle with Customer Name and Amount paid now inputs (auto-generating debt record), and fixed footer Sell button rendered via root navigator to guarantee zero nav bar overlap.
7. **Stock adjustments**: record damaged, lost, returned, personal use, or count corrections with live cost and stock deduction.
8. **Shift system & Cash Reconciliation**: automatic tracking of money earned during shift broken down by account (Cash, Bank, Telebirr/Debit), automatic display of credit items today, and Close Shift sheet with drawer cash reconciliation and optional bank and debit reconciliation inputs.
9. **More**: suppliers, expenses, debts (including credit sales receivables), categories & colors, stock adjustments, reconciliation, shift history, export, backup, settings.
10. **Quick calculator**: app-shell floating trigger button, 20-entry calculation history, clipboard copy, and "Use result" action.

## 7.1 Mini calculator behavior

- Opens as a bottom sheet from the calculator icon inside any money field.
- Keys: 0-9, `.`, `+ - x /`, `%`, clear, backspace.
- Starts with the current field value if there is one.
- "Use result" writes the value back and closes. Invalid expressions show a gentle error, never crash.

## 8. Motion

- Page transitions: 250 to 300 ms, ease-out.
- Animated number counters on the dashboard.
- Button press scale feedback (0.97).
- Light haptic on: save, sold, delete confirm.
- Respect the system "reduce motion" setting.

## 9. Responsive and flexible layout

- No fixed pixel layouts. Use `LayoutBuilder`, `Flexible`, `Expanded`, `Wrap`.
- Must work on small phones (360 dp wide) up to tablets, portrait and landscape.
- Must work with large system text sizes without overflow.
- Test with text scale 1.0, 1.3 and 1.6.

## 10. Empty, loading and error states

- Every list has a friendly empty state (icon, one short line, one action button).
- Loading uses skeleton shimmers, not spinners alone.
- Errors use a calm message and a retry action. Never show raw exceptions.

## 11. Accessibility

- Contrast ratio at least 4.5:1 for text in both themes.
- Tap targets at least 48x48 dp.
- Semantic labels on icon-only buttons.
- Never rely on color alone: profit and loss also use +/- signs and arrows.

## 12. Tone of voice

Short, friendly, simple English. Example: "No purchases yet. Add your first one." Avoid accounting jargon.

## 13. App Icon & Launcher Branding

- **Brand Colors**:
  - Background: Deep Navy `#0D2045` (`values/colors.xml`).
  - Brand Mark: Bright Mint/Green `#3EE08F` and Clean White `#FFFFFF`.
- **Adaptive Icon (Android 8.0+ / API 26+)**:
  - `mipmap-anydpi-v26/ic_launcher.xml` with solid background and 16% safe-zone inset foreground.
  - Guarantees full legibility without logo clipping across circular, squircle, or rounded-rect system masks.
- **Legacy Density Mipmaps**:
  - `mipmap-mdpi` (48px), `mipmap-hdpi` (72px), `mipmap-xhdpi` (96px), `mipmap-xxhdpi` (144px), `mipmap-xxxhdpi` (192px).
  - Anti-aliased transparent outer corners to prevent corner clipping artifacts.

## 14. Modern Splash Screen & Visual Aura

- **Background & Lighting**:
  - Base background token: Obsidian midnight navy `#0B1020` (free of muddy pitch-dark `#070B14`).
  - Luminous multi-layered radial bloom with electric blue (`#3D6BFF` at 0.35 alpha) and deep cobalt (`#1E3A8A` at 0.18 alpha).
  - Floating ambient decorative orbs: subtle electric blue top-right and soft indigo (`#6366F1`) bottom-left.
  - Zero murky green gradients or tints.
- **Branded Emblem**:
  - Dark glassmorphic squircle (`#1E2846` to `#11172A`) with 28dp corner radius and crisp 22% white border.
  - Dual-layer electric-blue and azure drop shadow (`#3D6BFF` and `#60A5FA`).
  - Continuous breathing halo ring in electric blue and azure.
- **Typography & Accents**:
  - Brand title: `Fira Bonda` in Sora font, bold 34, with soft blue neon glow shadow.
  - Store category badge: Modern electric blue translucent pill (`#3D6BFF` at 15% fill, `#60A5FA` at 35% border) with `#93C5FD` text and storefront icon.
  - High-contrast subtitle (0.85 opacity) and feature chips (`100% Offline`, `Real Profit`, `Private Data`) with `#93C5FD` icons and `#F1F5F9` text.
- **Progress Line & Micro-Copy**:
  - Active progress line with electric-blue to sky-cyan gradient (`#2563EB` → `#3D6BFF` → `#38BDF8`) and glowing blue drop shadow.
  - Clear offline database status indicators (`#CBD5E1`) and subtle "Tap anywhere to start" hint.
- **System Integration**:
  - `AnnotatedRegion<SystemUiOverlayStyle>` sets edge-to-edge transparent status and navigation bars with light icons to prevent Android system bar scrim dimming.
  - Extended 2.8s display duration with tap-to-skip anywhere.

