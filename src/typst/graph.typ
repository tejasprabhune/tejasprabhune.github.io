// Node graphs and function plots for posts. The editor loads this file into
// every compile as /graph.typ and imports its public names automatically.
//
// Node graphs (y grows downward, like rows on a page):
//
//   #graph(
//     node("x1", (0, 0), label: $X_1$, label-pos: top),
//     node("y1", (0, 1), label: $Y_1$, label-pos: bottom, fill: shaded),
//     edge("x1", "y1", label: $B$, label-pos: left),
//     edge("x1", (2, 0), style: "dashed", bend: 0.3),
//     dots((1, 0)),
//     text-at((-0.6, 0), $pi$),
//   )
//
// Plots (data coordinates, y grows upward):
//
//   #plot(x: (0, 3), y: (-5, 5), x-label: $x$,
//     func(x => calc.ln(x), domain: (0.001, 3)),
//     func(x => 2 * x - calc.ln(2) - 1, style: "dashed"),
//     data(((0, 0), (1, 1), (2, 0.5)), marks: "dot"),
//     vline(1, style: "dotted"),
//   )

#let shaded = luma(78%)

#let stroke-of(style, thickness) = {
  let thickness = if type(thickness) == length { thickness } else { thickness * 1pt }
  if style == "dashed" {
    (paint: black, thickness: thickness, dash: (3pt, 2pt))
  } else if style == "dotted" {
    (paint: black, thickness: thickness, dash: (thickness, 1.8pt), cap: "round")
  } else {
    (paint: black, thickness: thickness)
  }
}

// Alignment to unit offset, with y growing downward.
#let dir-of(pos) = {
  let dx = if pos.x == left { -1 } else if pos.x == right { 1 } else { 0 }
  let dy = if pos.y == top { -1 } else if pos.y == bottom { 1 } else { 0 }
  (dx, dy)
}

// Places `body` beside the point (x, y) (in pt, y down) in direction `dir`,
// keeping `clearance` between the point and the near edge of the body.
#let put-at(x, y, body, dir: (0, 0), clearance: 0.0) = {
  let (dx, dy) = dir
  let size = measure(body)
  let c = if dx != 0 and dy != 0 { clearance * 0.75 } else { clearance }
  let px = x + dx * c
  let py = y + dy * c
  place(
    top + left,
    dx: px * 1pt - size.width * (1 - dx) / 2,
    dy: py * 1pt - size.height * (1 - dy) / 2,
    body,
  )
}

#let vsub(a, b) = (a.at(0) - b.at(0), a.at(1) - b.at(1))
#let vadd(a, b) = (a.at(0) + b.at(0), a.at(1) + b.at(1))
#let vscale(a, s) = (a.at(0) * s, a.at(1) * s)
#let vlen(a) = calc.sqrt(a.at(0) * a.at(0) + a.at(1) * a.at(1))
#let vnorm(a) = {
  let l = vlen(a)
  if l == 0 { (0, 0) } else { vscale(a, 1 / l) }
}

#let arrowhead(tip, d, size) = {
  let (tx, ty) = tip
  let (dx, dy) = d
  let (nx, ny) = (-dy, dx)
  let w = size * 0.4
  let bx = tx - dx * size
  let by = ty - dy * size
  place(
    top + left,
    polygon(
      fill: black,
      (tx * 1pt, ty * 1pt),
      ((bx + nx * w) * 1pt, (by + ny * w) * 1pt),
      ((bx - nx * w) * 1pt, (by - ny * w) * 1pt),
    ),
  )
}

#let node(
  id,
  at,
  label: none,
  label-pos: center,
  fill: none,
  shape: "circle",
  radius: auto,
) = (
  kind: "node",
  id: id,
  pos: at,
  label: label,
  label-pos: label-pos,
  fill: fill,
  shape: shape,
  radius: radius,
)

#let edge(
  from,
  to,
  label: none,
  label-pos: auto,
  style: "solid",
  bend: 0,
  arrow: true,
) = (
  kind: "edge",
  from: from,
  to: to,
  label: label,
  label-pos: label-pos,
  style: style,
  bend: bend,
  arrow: arrow,
)

#let text-at(at, body) = (kind: "text", pos: at, body: body)

#let ellipsis = $dots.c$

#let dots(at) = text-at(at, ellipsis)

// Lays out nodes on a grid with `unit` spacing. Edges connect node ids or
// raw (x, y) coordinates and stop short of the circles they touch. A positive
// `bend` bows the edge to the right of its direction of travel (so an edge
// heading down bows to the left of the page), as a fraction of its length.
#let graph(
  unit: 1.8cm,
  radius: 0.36cm,
  thickness: 0.7pt,
  gap: 0.18cm,
  pad: auto,
  arrow-size: 7pt,
  ..items,
) = context {
  let items = items.pos()
  let unit = unit.to-absolute().pt()
  let radius = radius.to-absolute().pt()
  let thickness = thickness.to-absolute().pt()
  let gap = gap.to-absolute().pt()
  let arrow-size = arrow-size.to-absolute().pt()
  let pad = if pad == auto { radius + 0.75cm.pt() } else { pad.to-absolute().pt() }

  let placed = items.filter(it => "pos" in it)
  assert(placed.len() > 0, message: "graph needs at least one node")
  let xs = placed.map(it => it.pos.at(0))
  let ys = placed.map(it => it.pos.at(1))
  let (minx, maxx) = (calc.min(..xs), calc.max(..xs))
  let (miny, maxy) = (calc.min(..ys), calc.max(..ys))
  let width = (maxx - minx) * unit + 2 * pad
  let height = (maxy - miny) * unit + 2 * pad
  let to-pt(at) = (pad + (at.at(0) - minx) * unit, pad + (at.at(1) - miny) * unit)

  let nodes = (:)
  for it in items {
    if it.kind == "node" {
      let r = if it.radius == auto { radius } else { it.radius.to-absolute().pt() }
      nodes.insert(it.id, (center: to-pt(it.pos), radius: r, shape: it.shape))
    }
  }

  let resolve(ref) = {
    if type(ref) == array {
      (center: to-pt(ref), radius: gap, shape: "none")
    } else {
      assert(ref in nodes, message: "graph: unknown node " + repr(ref))
      nodes.at(ref)
    }
  }

  let line-stroke = stroke-of("solid", thickness)

  let draw-node(it) = {
    let n = nodes.at(it.id)
    let (cx, cy) = n.center
    let r = n.radius
    if it.shape == "circle" {
      place(
        top + left,
        dx: (cx - r) * 1pt,
        dy: (cy - r) * 1pt,
        circle(radius: r * 1pt, fill: it.fill, stroke: line-stroke),
      )
    } else if it.shape == "rect" {
      place(
        top + left,
        dx: (cx - r) * 1pt,
        dy: (cy - r) * 1pt,
        rect(width: 2 * r * 1pt, height: 2 * r * 1pt, fill: it.fill, stroke: line-stroke),
      )
    }
    if it.label != none {
      let dir = dir-of(it.label-pos)
      let clearance = if it.shape == "none" { gap } else { r + gap }
      put-at(cx, cy, it.label, dir: dir, clearance: clearance)
    }
  }

  let draw-edge(it) = {
    let a = resolve(it.from)
    let b = resolve(it.to)
    let (ca, cb) = (a.center, b.center)
    let chord = vsub(cb, ca)
    let length = vlen(chord)
    let d = vnorm(chord)
    let normal = (-d.at(1), d.at(0))
    let mid = vadd(ca, vscale(chord, 0.5))
    let control = vadd(mid, vscale(normal, it.bend * length))
    let d-start = if it.bend == 0 { d } else { vnorm(vsub(control, ca)) }
    let d-end = if it.bend == 0 { d } else { vnorm(vsub(cb, control)) }
    let start = vadd(ca, vscale(d-start, a.radius + gap * 0.35))
    let tip = vsub(cb, vscale(d-end, b.radius + gap * 0.35))
    let head = if it.arrow { arrow-size } else { 0 }
    let end = vsub(tip, vscale(d-end, head * 0.75))
    let stroke = stroke-of(it.style, thickness)
    let pt = p => (p.at(0) * 1pt, p.at(1) * 1pt)
    if it.bend == 0 {
      place(top + left, line(start: pt(start), end: pt(end), stroke: stroke))
    } else {
      place(
        top + left,
        curve(stroke: stroke, curve.move(pt(start)), curve.quad(pt(control), pt(end))),
      )
    }
    if it.arrow { arrowhead(tip, d-end, arrow-size) }
    if it.label != none {
      // Point on the curve halfway along, then nudged to the label side.
      let on-curve = vadd(
        vadd(vscale(start, 0.25), vscale(control, 0.5)),
        vscale(end, 0.25),
      )
      let pos = if it.label-pos == auto {
        if calc.abs(chord.at(0)) >= calc.abs(chord.at(1)) { top } else { left }
      } else {
        it.label-pos
      }
      put-at(on-curve.at(0), on-curve.at(1), it.label, dir: dir-of(pos), clearance: gap * 1.3)
    }
  }

  let draw-text(it) = {
    let (x, y) = to-pt(it.pos)
    put-at(x, y, it.body)
  }

  box(width: width * 1pt, height: height * 1pt, {
    for it in items {
      if it.kind == "edge" { draw-edge(it) }
    }
    for it in items {
      if it.kind == "node" { draw-node(it) } else if it.kind == "text" { draw-text(it) }
    }
  })
}

// Plot series. Functions are sampled over `domain` (default: the x range).
#let func(
  f,
  domain: auto,
  style: "solid",
  samples: auto,
  label: none,
  label-at: auto,
  label-pos: top,
  thickness: auto,
) = (
  kind: "func",
  f: f,
  domain: domain,
  style: style,
  samples: samples,
  label: label,
  label-at: label-at,
  label-pos: label-pos,
  thickness: thickness,
)

#let data(
  points,
  style: "solid",
  marks: none,
  label: none,
  label-at: auto,
  label-pos: top,
  thickness: auto,
) = (
  kind: "data",
  points: points,
  style: style,
  marks: marks,
  label: label,
  label-at: label-at,
  label-pos: label-pos,
  thickness: thickness,
)

#let vline(x, style: "dotted", thickness: auto) = (kind: "vline", x: x, style: style, thickness: thickness)
#let hline(y, style: "dotted", thickness: auto) = (kind: "hline", y: y, style: style, thickness: thickness)

#let finite(v) = type(v) == int or (type(v) == float and not v.is-nan() and not v.is-infinite())

#let nice-step(range) = {
  let raw = range / 5
  let mag = calc.pow(10.0, calc.floor(calc.log(raw, base: 10)))
  let r = raw / mag
  let m = if r < 1.5 { 1 } else if r < 3 { 2 } else if r < 7 { 5 } else { 10 }
  m * mag
}

#let ticks-of(spec, lo, hi) = {
  if type(spec) == array { return spec }
  let step = if spec == auto { nice-step(hi - lo) } else { spec }
  let out = ()
  let i = calc.ceil(lo / step - 1e-9)
  while i * step <= hi + 1e-9 {
    out.push(i * step)
    i += 1
  }
  out
}

#let fmt-tick(v) = {
  let r = calc.round(v, digits: 6)
  let s = if r == calc.trunc(r) { str(int(r)) } else { str(r) }
  s.replace("-", "\u{2212}")
}

// Liang-Barsky clipping of a polyline against the unit square, returning a
// list of visible polylines.
#let clip-polyline(pts) = {
  let out = ()
  let run = ()
  let prev-kept = false
  for i in range(1, pts.len()) {
    let p0 = pts.at(i - 1)
    let p1 = pts.at(i)
    if p0 == none or p1 == none {
      if run.len() > 1 { out.push(run) }
      run = ()
      prev-kept = false
      continue
    }
    let (x0, y0) = p0
    let (x1, y1) = p1
    let (dx, dy) = (x1 - x0, y1 - y0)
    let t0 = 0.0
    let t1 = 1.0
    let visible = true
    for (p, q) in ((-dx, x0), (dx, 1 - x0), (-dy, y0), (dy, 1 - y0)) {
      if p == 0 {
        if q < 0 { visible = false }
      } else {
        let t = q / p
        if p < 0 { if t > t0 { t0 = t } } else { if t < t1 { t1 = t } }
      }
    }
    if not visible or t0 > t1 {
      if run.len() > 1 { out.push(run) }
      run = ()
      prev-kept = false
      continue
    }
    let a = (x0 + dx * t0, y0 + dy * t0)
    let b = (x0 + dx * t1, y0 + dy * t1)
    if t0 > 0 or not prev-kept {
      if run.len() > 1 { out.push(run) }
      run = (a, b)
    } else {
      run.push(b)
    }
    prev-kept = t1 >= 1
  }
  if run.len() > 1 { out.push(run) }
  out
}

// A framed plot in the gnuplot style: full border, inward ticks mirrored on
// the far sides, tick labels outside, axis labels below and to the left.
#let plot(
  x: (0, 1),
  y: (0, 1),
  width: 10cm,
  height: 6.5cm,
  x-ticks: auto,
  y-ticks: auto,
  x-label: none,
  y-label: none,
  tick-size: 0.14cm,
  mirror: true,
  thickness: 0.7pt,
  samples: 300,
  label-size: 0.9em,
  ..items,
) = context {
  let items = items.pos()
  let w = width.to-absolute().pt()
  let h = height.to-absolute().pt()
  let tick-size = tick-size.to-absolute().pt()
  let thickness = thickness.to-absolute().pt()
  let gap = 0.12cm.pt()
  let (x0, x1) = x
  let (y0, y1) = y
  let to-unit(p) = ((p.at(0) - x0) / (x1 - x0), (p.at(1) - y0) / (y1 - y0))
  let to-pt(u) = (u.at(0) * w, h - u.at(1) * h)

  let tick-text(v) = text(size: label-size, fmt-tick(v))
  let xt = ticks-of(x-ticks, x0, x1)
  let yt = ticks-of(y-ticks, y0, y1)
  let y-labels = yt.map(tick-text)
  let x-labels = xt.map(tick-text)
  let y-label-width = calc.max(0pt, ..y-labels.map(l => measure(l).width)).pt()
  let x-label-height = calc.max(0pt, ..x-labels.map(l => measure(l).height)).pt()
  let axis-x-size = if x-label == none { (width: 0pt, height: 0pt) } else { measure(x-label) }
  let axis-y-size = if y-label == none { (width: 0pt, height: 0pt) } else { measure(y-label) }
  let m-left = y-label-width + gap + (if y-label == none { 0 } else { axis-y-size.width.pt() + 2 * gap })
  let m-bottom = x-label-height + gap + (if x-label == none { 0 } else { axis-x-size.height.pt() + 2 * gap })
  let m-right = calc.max(0.0, measure(x-labels.last()).width.pt() / 2 - 0.3cm.pt())
  let m-top = calc.max(0.0, measure(y-labels.last()).height.pt() / 2 - 0.3cm.pt())

  let frame-stroke = stroke-of("solid", thickness)
  let pt = p => (p.at(0) * 1pt, p.at(1) * 1pt)

  let series-thickness(it) = if it.thickness == auto { thickness * 1.15 } else { it.thickness.to-absolute().pt() }

  let draw-polyline(pts, stroke) = {
    for run in clip-polyline(pts) {
      let segs = run.map(u => pt(to-pt(u)))
      place(
        top + left,
        curve(
          stroke: stroke,
          curve.move(segs.first()),
          ..segs.slice(1).map(p => curve.line(p)),
        ),
      )
    }
  }

  let draw-label(it, anchor-point) = {
    if it.label == none { return }
    let u = to-unit(anchor-point)
    let (px, py) = to-pt(u)
    put-at(px, py, text(size: label-size, it.label), dir: dir-of(it.label-pos), clearance: gap)
  }

  let draw-func(it) = {
    let (a, b) = if it.domain == auto { (x0, x1) } else { it.domain }
    let a = calc.max(a, x0)
    let b = calc.min(b, x1)
    let n = if it.samples == auto { samples } else { it.samples }
    let pts = ()
    for i in range(n + 1) {
      let xv = a + (b - a) * i / n
      let yv = (it.f)(xv)
      pts.push(if finite(yv) { to-unit((xv, yv)) } else { none })
    }
    draw-polyline(pts, stroke-of(it.style, series-thickness(it)))
    if it.label != none {
      let lx = if it.label-at == auto { b } else { calc.max(a, calc.min(b, it.label-at)) }
      draw-label(it, (lx, (it.f)(lx)))
    }
  }

  let draw-data(it) = {
    let pts = it.points.map(p => if finite(p.at(1)) { to-unit(p) } else { none })
    if it.style != none { draw-polyline(pts, stroke-of(it.style, series-thickness(it))) }
    if it.marks != none {
      let r = 1.7pt
      for u in pts {
        if u == none or u.at(0) < 0 or u.at(0) > 1 or u.at(1) < 0 or u.at(1) > 1 { continue }
        let (px, py) = to-pt(u)
        place(
          top + left,
          dx: px * 1pt - r,
          dy: py * 1pt - r,
          circle(
            radius: r,
            fill: if it.marks == "circle" { white } else { black },
            stroke: frame-stroke,
          ),
        )
      }
    }
    if it.label != none and it.points.len() > 0 {
      let anchor = if it.label-at == auto {
        it.points.last()
      } else {
        it.points.sorted(key: p => calc.abs(p.at(0) - it.label-at)).first()
      }
      draw-label(it, anchor)
    }
  }

  let draw-rule(it) = {
    let stroke = stroke-of(it.style, series-thickness(it) * 0.8)
    if it.kind == "vline" {
      let u = to-unit((it.x, y0)).at(0)
      if u < 0 or u > 1 { return }
      place(top + left, line(start: (u * w * 1pt, 0pt), end: (u * w * 1pt, h * 1pt), stroke: stroke))
    } else {
      let u = to-unit((x0, it.y)).at(1)
      if u < 0 or u > 1 { return }
      place(top + left, line(start: (0pt, h * (1 - u) * 1pt), end: (w * 1pt, h * (1 - u) * 1pt), stroke: stroke))
    }
  }

  let area = box(width: w * 1pt, height: h * 1pt, clip: true, {
    for it in items {
      if it.kind == "func" { draw-func(it) } else if it.kind == "data" { draw-data(it) } else if it.kind == "vline" or it.kind == "hline" { draw-rule(it) }
    }
  })

  let ticks = {
    for v in xt {
      let px = to-pt(to-unit((v, y0))).at(0)
      if px < -0.01 or px > w + 0.01 { continue }
      place(top + left, line(start: (px * 1pt, h * 1pt), end: (px * 1pt, (h - tick-size) * 1pt), stroke: frame-stroke))
      if mirror {
        place(top + left, line(start: (px * 1pt, 0pt), end: (px * 1pt, tick-size * 1pt), stroke: frame-stroke))
      }
    }
    for v in yt {
      let py = to-pt(to-unit((x0, v))).at(1)
      if py < -0.01 or py > h + 0.01 { continue }
      place(top + left, line(start: (0pt, py * 1pt), end: (tick-size * 1pt, py * 1pt), stroke: frame-stroke))
      if mirror {
        place(top + left, line(start: (w * 1pt, py * 1pt), end: ((w - tick-size) * 1pt, py * 1pt), stroke: frame-stroke))
      }
    }
  }

  let labels = {
    for (v, l) in xt.zip(x-labels) {
      let px = to-pt(to-unit((v, y0))).at(0)
      if px < -0.01 or px > w + 0.01 { continue }
      put-at(px, h, l, dir: (0, 1), clearance: gap)
    }
    for (v, l) in yt.zip(y-labels) {
      let py = to-pt(to-unit((x0, v))).at(1)
      if py < -0.01 or py > h + 0.01 { continue }
      put-at(0, py, l, dir: (-1, 0), clearance: gap)
    }
    if x-label != none {
      put-at(w / 2, h + x-label-height + gap, x-label, dir: (0, 1), clearance: 1.5 * gap)
    }
    if y-label != none {
      put-at(-(y-label-width + gap), h / 2, y-label, dir: (-1, 0), clearance: 1.5 * gap)
    }
    for it in items {
      if it.kind == "text" {
        let (px, py) = to-pt(to-unit(it.pos))
        put-at(px, py, text(size: label-size, it.body))
      }
    }
  }

  box(
    width: (m-left + w + m-right) * 1pt,
    height: (m-top + h + m-bottom) * 1pt,
    place(top + left, dx: m-left * 1pt, dy: m-top * 1pt, {
      place(top + left, area)
      place(top + left, rect(width: w * 1pt, height: h * 1pt, stroke: frame-stroke))
      ticks
      labels
    }),
  )
}
