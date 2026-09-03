// Margin sidenotes for published posts. Notes are anchored to the rendered
// position of their #side marker: the focused note aligns exactly with its
// anchor and the rest flow around it without overlapping, the way document
// comment rails behave. The marker superscripts compile to svg links
// (side:N), which double as the click targets.

export type SideNote = { n: number; x: number; y: number; svg: string };

const GAP = 10;

export function initSidenotes(content: HTMLElement, notes: SideNote[]) {
  if (!notes.length) return;
  notes = [...notes].sort((a, b) => a.y - b.y);

  // Wrap the content so the rail can be positioned against it.
  const wrap = document.createElement('div');
  wrap.className = 'post-body';
  content.parentNode!.insertBefore(wrap, content);
  wrap.append(content);

  const rail = document.createElement('div');
  rail.className = 'side-rail';
  wrap.append(rail);

  // The show/hide control sits under the post date, above the text.
  const toggle = document.createElement('button');
  toggle.type = 'button';
  toggle.className = 'side-toggle';
  const dateLine = wrap.parentElement?.querySelector('.post-date');
  if (dateLine) dateLine.after(toggle);
  else wrap.before(toggle);

  // Marker links inside the compiled svg are the primary click targets.
  // Documents compiled before markers became links fall back to invisible
  // positioned hotspots.
  const markers = new Map<number, Element>();
  for (const anchor of content.querySelectorAll('svg a')) {
    const href = anchor.getAttribute('xlink:href') ?? anchor.getAttribute('href') ?? '';
    const match = /^side:(\d+)$/.exec(href);
    if (!match) continue;
    const n = Number(match[1]);
    anchor.classList.add('side-link');
    anchor.removeAttribute('target');
    anchor.addEventListener('click', event => {
      event.preventDefault();
      select(n);
    });
    markers.set(n, anchor);
  }

  // The anchors are empty click rects; the number's glyphs are separate
  // elements that happen to sit inside the rect, found by hit-testing so
  // the selected marker can be faked bold with a stroke.
  const markerGlyphs = new Map<number, Element[]>();
  if (markers.size) {
    const uses = [...content.querySelectorAll('svg use')];
    for (const [n, anchor] of markers) {
      const box = anchor.getBoundingClientRect();
      markerGlyphs.set(
        n,
        uses.filter(use => {
          const rect = use.getBoundingClientRect();
          const cx = rect.left + rect.width / 2;
          const cy = rect.top + rect.height / 2;
          return cx >= box.left - 1 && cx <= box.right + 1 && cy >= box.top - 1 && cy <= box.bottom + 1;
        }),
      );
    }
  }

  const hotspots = new Map<number, HTMLButtonElement>();
  for (const note of notes) {
    if (markers.has(note.n)) continue;
    const hot = document.createElement('button');
    hot.type = 'button';
    hot.className = 'side-hot';
    hot.title = `sidenote ${note.n}`;
    hot.addEventListener('click', () => select(note.n));
    content.append(hot);
    hotspots.set(note.n, hot);
  }

  const cards = new Map<number, HTMLElement>();
  for (const note of notes) {
    const card = document.createElement('article');
    card.className = 'side-card collapsed';
    const num = document.createElement('span');
    num.className = 'side-num';
    num.textContent = String(note.n);
    const body = document.createElement('div');
    body.className = 'side-note-body';
    body.innerHTML = note.svg;
    card.append(num, body);
    card.addEventListener('click', event => {
      event.stopPropagation();
      select(note.n);
    });
    rail.append(card);
    cards.set(note.n, card);
  }

  // Fallback list shown instead of the rail on narrow screens.
  const list = document.createElement('section');
  list.className = 'side-list';
  const heading = document.createElement('h2');
  heading.textContent = 'Sidenotes';
  const items = document.createElement('ol');
  for (const note of notes) {
    const item = document.createElement('li');
    item.id = `sidenote-${note.n}`;
    const body = document.createElement('div');
    body.className = 'side-note-body';
    body.innerHTML = note.svg;
    item.append(body);
    items.append(item);
  }
  list.append(heading, items);
  wrap.after(list);

  let showAll = false;
  let focused: number | null = null;

  // Narrow viewports get the footnote list instead of the split view.
  const narrow = window.matchMedia('(max-width: 1080px)');
  const main = wrap.closest('main');

  function railVisible() {
    return !narrow.matches;
  }

  // Notes open the split view: text in the left half, notes in the right.
  function notesOpen() {
    return showAll || focused != null;
  }

  function select(n: number) {
    if (!railVisible()) {
      document.getElementById(`sidenote-${n}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      return;
    }
    focused = focused === n && !showAll ? null : n;
    update();
  }

  function anchors(): Map<number, number> {
    const svg = content.querySelector('svg');
    const out = new Map<number, number>();
    if (!svg) return out;
    const vb = (svg as any).viewBox?.baseVal;
    if (!vb || !vb.height) return out;
    const svgRect = svg.getBoundingClientRect();
    const wrapRect = wrap.getBoundingClientRect();
    const contentRect = content.getBoundingClientRect();
    const scale = svgRect.height / vb.height;
    for (const note of notes) {
      out.set(note.n, svgRect.top - wrapRect.top + note.y * scale);
      const hot = hotspots.get(note.n);
      if (hot) {
        hot.style.left = `${svgRect.left - contentRect.left + note.x * (svgRect.width / vb.width)}px`;
        hot.style.top = `${svgRect.top - contentRect.top + note.y * scale}px`;
      }
    }
    return out;
  }

  function update() {
    for (const note of notes) {
      const focusedNote = focused === note.n;
      const card = cards.get(note.n)!;
      card.classList.toggle('collapsed', !(showAll || focusedNote));
      card.classList.toggle('focused', focusedNote);
      markers.get(note.n)?.classList.toggle('side-active', focusedNote);
      for (const glyph of markerGlyphs.get(note.n) ?? []) {
        glyph.classList.toggle('side-bold', focusedNote);
      }
      hotspots.get(note.n)?.classList.toggle('active', focusedNote);
    }
    const open = notesOpen();
    main?.classList.toggle('notes-open', open);
    toggle.textContent = `${open ? 'Hide' : 'Show'} notes (${notes.length})`;
    if (open) {
      layout();
    } else {
      wrap.style.minHeight = '';
    }
  }

  function layout() {
    const anchor = anchors();
    if (!anchor.size) return;
    const minTop = 0;
    const heights = notes.map(note => cards.get(note.n)!.offsetHeight);
    const tops: number[] = new Array(notes.length);
    const focusIndex = focused == null ? -1 : notes.findIndex(note => note.n === focused);

    if (focusIndex >= 0) {
      tops[focusIndex] = anchor.get(notes[focusIndex].n)!;
      for (let i = focusIndex - 1; i >= 0; i--) {
        tops[i] = Math.min(anchor.get(notes[i].n)!, tops[i + 1] - GAP - heights[i]);
      }
      for (let i = focusIndex + 1; i < notes.length; i++) {
        tops[i] = Math.max(anchor.get(notes[i].n)!, tops[i - 1] + heights[i - 1] + GAP);
      }
    } else {
      for (let i = 0; i < notes.length; i++) {
        tops[i] = Math.max(anchor.get(notes[i].n)!, i ? tops[i - 1] + heights[i - 1] + GAP : minTop);
      }
    }

    // Nothing may cover the toggle or a previous card; push the chain down.
    for (let i = 0; i < notes.length; i++) {
      tops[i] = Math.max(tops[i], i ? tops[i - 1] + heights[i - 1] + GAP : minTop);
    }

    let bottom = 0;
    for (let i = 0; i < notes.length; i++) {
      cards.get(notes[i].n)!.style.top = `${tops[i]}px`;
      bottom = tops[i] + heights[i];
    }
    wrap.style.minHeight = `${bottom}px`;
  }

  toggle.addEventListener('click', () => {
    if (notesOpen()) {
      showAll = false;
      focused = null;
    } else {
      showAll = true;
    }
    update();
  });
  narrow.addEventListener('change', () => update());

  // With every note open, follow the reader: focus the note whose anchor is
  // closest to the middle of the viewport.
  let scrollQueued = false;
  window.addEventListener('scroll', () => {
    if (!showAll || !railVisible() || scrollQueued) return;
    scrollQueued = true;
    requestAnimationFrame(() => {
      scrollQueued = false;
      const wrapTop = wrap.getBoundingClientRect().top;
      const center = window.innerHeight / 2 - wrapTop;
      const anchor = anchors();
      let best: number | null = null;
      let bestDistance = Infinity;
      for (const note of notes) {
        const distance = Math.abs((anchor.get(note.n) ?? 0) - center);
        if (distance < bestDistance) {
          bestDistance = distance;
          best = note.n;
        }
      }
      if (best != null && best !== focused) {
        focused = best;
        update();
      }
    });
  }, { passive: true });

  const svg = content.querySelector('svg');
  if (svg && 'ResizeObserver' in window) {
    new ResizeObserver(() => update()).observe(svg);
  }
  window.addEventListener('resize', () => update());

  update();
}
