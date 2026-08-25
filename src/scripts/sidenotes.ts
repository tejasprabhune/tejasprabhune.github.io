// Margin sidenotes for published posts. Notes are anchored to the rendered
// position of their #side marker: the focused note aligns exactly with its
// anchor and the rest flow around it without overlapping, the way document
// comment rails behave.

export type SideNote = { n: number; x: number; y: number; svg: string };

const GAP = 10;

export function initSidenotes(content: HTMLElement, notes: SideNote[], meta: HTMLElement | null) {
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

  const hotspots = new Map<number, HTMLButtonElement>();
  const cards = new Map<number, HTMLElement>();

  for (const note of notes) {
    const hot = document.createElement('button');
    hot.type = 'button';
    hot.className = 'side-hot';
    hot.title = `sidenote ${note.n}`;
    hot.addEventListener('click', () => select(note.n));
    content.append(hot);
    hotspots.set(note.n, hot);

    const card = document.createElement('article');
    card.className = 'side-card collapsed';
    const chip = document.createElement('button');
    chip.type = 'button';
    chip.className = 'side-chip';
    chip.textContent = String(note.n);
    const body = document.createElement('div');
    body.className = 'side-note-body';
    body.innerHTML = note.svg;
    card.append(chip, body);
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

  if (!meta) {
    meta = document.createElement('p');
    meta.className = 'post-date';
    wrap.before(meta);
  }
  const toggle = document.createElement('button');
  toggle.type = 'button';
  toggle.className = 'side-toggle';
  if (meta.textContent?.trim()) meta.append(' · ');
  meta.append(toggle);

  let showAll = false;
  let focused: number | null = null;

  function railVisible() {
    return getComputedStyle(rail).display !== 'none';
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
      const hot = hotspots.get(note.n)!;
      hot.style.left = `${svgRect.left - contentRect.left + note.x * (svgRect.width / vb.width)}px`;
      hot.style.top = `${svgRect.top - contentRect.top + note.y * scale}px`;
    }
    return out;
  }

  function update() {
    for (const note of notes) {
      const card = cards.get(note.n)!;
      const expanded = showAll || focused === note.n;
      card.classList.toggle('collapsed', !expanded);
      card.classList.toggle('focused', focused === note.n);
      hotspots.get(note.n)!.classList.toggle('active', focused === note.n);
    }
    toggle.textContent = showAll ? 'hide sidenotes' : `sidenotes (${notes.length})`;
    layout();
  }

  function layout() {
    const anchor = anchors();
    if (!anchor.size) return;
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
        tops[i] = Math.max(anchor.get(notes[i].n)!, i ? tops[i - 1] + heights[i - 1] + GAP : 0);
      }
    }

    // Nothing may stick out above the rail; push the chain back down.
    for (let i = 0; i < notes.length; i++) {
      tops[i] = Math.max(tops[i], i ? tops[i - 1] + heights[i - 1] + GAP : 0);
    }

    let bottom = 0;
    for (let i = 0; i < notes.length; i++) {
      cards.get(notes[i].n)!.style.top = `${tops[i]}px`;
      bottom = tops[i] + heights[i];
    }
    wrap.style.minHeight = `${bottom}px`;
  }

  toggle.addEventListener('click', () => {
    showAll = !showAll;
    if (!showAll) focused = null;
    update();
  });

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
