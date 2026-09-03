# Figure library reference

Every document is compiled with these names already imported:
`graph, node, edge, dots, text-at, shaded, plot, func, data, vline, hline`
(from /graph.typ) and `side` (sidenotes: `#side[...]` renders a numbered margin note).

House style: pages are 16cm wide, body text 12pt Neue Montreal, math in New Computer
Modern. Figures are wrapped in `#figure(..., caption: [...])`. Labels are typeset with
typst math, e.g. `$X_1$`, `$X_t^((k))$`, `$cal(N)(0, 1)$`, `$pi$`.

## Node graphs

`graph(unit: 1.8cm, radius: 0.36cm, thickness: 0.7pt, gap: 0.18cm, pad: auto, arrow-size: 7pt, ..items)`

Coordinates are grid units, x to the right and y **downward** (row 0 is the top row).
The canvas is sized automatically from the items.

- `node(id, (x, y), label: none, label-pos: center, fill: none, shape: "circle", radius: auto)`
  - `label-pos`: `top`, `bottom`, `left`, `right`, `center`, or combos like `top + left`.
  - `fill: shaded` is the light gray for observed variables; `luma(45%)` a darker gray.
  - `shape`: `"circle"` (default), `"rect"` (square, e.g. a factor or a fixed parameter), `"none"` (just the label).
- `edge(from, to, label: none, label-pos: auto, style: "solid", bend: 0, arrow: true)`
  - `from`/`to` are node ids or raw `(x, y)` coordinates (useful for arrows into an ellipsis).
  - `style`: `"solid"`, `"dashed"`, `"dotted"`. `arrow: false` gives an undirected edge.
  - `bend` is a fraction of the edge length; positive bows to the right of the direction of travel, so an edge heading down bows to the left of the page. Use 0.25 to 0.4 for edges that must skip over intermediate rows.
  - `label-pos` defaults to `top` for mostly-horizontal edges and `left` for mostly-vertical ones.
- `dots((x, y))` draws a centered ellipsis; `text-at((x, y), body)` places arbitrary content.

Example, a hidden Markov model:

```typst
#figure(
  graph(
    text-at((-0.55, 0), $pi$),
    node("x1", (0, 0), label: $X_1$, label-pos: top),
    node("x2", (1, 0), label: $X_2$, label-pos: top),
    node("x3", (2, 0), label: $X_3$, label-pos: top),
    dots((3, 0)),
    node("xT", (4, 0), label: $X_T$, label-pos: top),
    node("y1", (0, 1), label: $Y_1$, label-pos: bottom, fill: shaded),
    node("y2", (1, 1), label: $Y_2$, label-pos: bottom, fill: shaded),
    node("y3", (2, 1), label: $Y_3$, label-pos: bottom, fill: shaded),
    node("yT", (4, 1), label: $Y_T$, label-pos: bottom, fill: shaded),
    edge("x1", "x2", label: $A$),
    edge("x2", "x3", label: $A$),
    edge("x1", "y1", label: $B$),
    edge("x2", "y2", label: $B$),
    edge("x3", "y3", label: $B$),
    edge("xT", "yT", label: $B$),
  ),
  caption: [A hidden Markov model.],
)
```

Example, a factorial HMM whose upper chains reach the observation with bent edges:

```typst
#figure(
  graph(
    unit: 1.6cm,
    node("a1", (0, 0), label: $X_1^((1))$, label-pos: top),
    node("a2", (1, 0), label: $X_2^((1))$, label-pos: top),
    node("b1", (0, 1), label: $X_1^((2))$, label-pos: top),
    node("b2", (1, 1), label: $X_2^((2))$, label-pos: top),
    node("y1", (0, 2), label: $Y_1$, label-pos: bottom, fill: luma(45%)),
    node("y2", (1, 2), label: $Y_2$, label-pos: bottom, fill: luma(45%)),
    dots((1.85, 0)), dots((1.85, 1)),
    edge("a1", "a2"), edge("a2", (1.75, 0)),
    edge("b1", "b2"), edge("b2", (1.75, 1)),
    edge("a1", "y1", bend: 0.35), edge("b1", "y1"),
    edge("a2", "y2", bend: 0.35), edge("b2", "y2"),
  ),
  caption: [A factorial HMM with two chains.],
)
```

Other common shapes: a Markov chain is one row of nodes with `edge` between neighbours; a
naive Bayes model is one hidden node at `(1, 0)` with observed children along row 1; a
plate can be faked with `node("plate", (x, y), shape: "rect", radius: 1.2cm, label: $N$, label-pos: bottom + right)`
placed before the nodes it should enclose.

## Plots

`plot(x: (lo, hi), y: (lo, hi), width: 10cm, height: 6.5cm, x-ticks: auto, y-ticks: auto, x-label: none, y-label: none, tick-size: 0.14cm, mirror: true, thickness: 0.7pt, samples: 300, label-size: 0.9em, ..items)`

Data coordinates, y **upward**. The frame is a full rectangle with inward ticks, mirrored
on the top and right unless `mirror: false`. Tick labels sit outside the frame; `x-label`
goes below and `y-label` to the left, both upright.

- `x-ticks`/`y-ticks`: `auto` picks a step of 1, 2 or 5 times a power of ten; a number is a step; an array lists exact values.
- `func(f, domain: auto, style: "solid", samples: auto, label: none, label-at: auto, label-pos: top, thickness: auto)`
  samples `f` (a typst closure `x => ...`) over `domain` (default: the x range). Values outside
  the y range are clipped at the frame, so functions may diverge inside the domain, but `f`
  itself must not panic: keep `calc.ln`, `calc.sqrt` and divisions away from their singularities
  by starting the domain slightly after them (e.g. `domain: (0.001, 3)`), and raise `samples`
  (400 to 800) for curves with steep parts.
- `data(points, style: "solid", marks: none, label: none, label-at: auto, label-pos: top, thickness: auto)`
  draws a polyline through `((x, y), ...)`; `marks: "dot"` or `"circle"` adds markers;
  `style: none` draws markers only.
- `vline(x, style: "dotted")` and `hline(y, style: "dotted")` draw reference lines.
- `text-at((x, y), body)` places content at data coordinates.
- Series labels: `label` is typeset next to the curve at x = `label-at` on the `label-pos` side.
  This is preferred over legends.
- Several related curves: build them with `..(0.5, 1, 2).map(l => func(x => l * x, style: "dashed"))`.

Example, variational bounds on the logarithm:

```typst
#figure(
  plot(
    x: (0, 3), y: (-5, 5),
    y-ticks: (-5, -3, -1, 1, 3, 5),
    x-label: $x$,
    func(x => calc.ln(x), domain: (0.001, 3), samples: 600),
    ..(0.5, 0.8, 1.2, 1.6, 2.2).map(l => func(x => l * x - calc.ln(l) - 1, style: "dashed")),
  ),
  caption: [Variational transformation of the logarithm.],
)
```

Example, two densities with sample points:

```typst
#figure(
  plot(
    x: (-4, 4), y: (0, 0.5), width: 8cm, height: 5cm,
    x-label: $x$, y-label: $p(x)$,
    func(x => calc.exp(-x * x / 2) / calc.sqrt(2 * calc.pi),
      label: $cal(N)(0, 1)$, label-at: -0.9, label-pos: left),
    func(x => calc.exp(-(x - 1) * (x - 1) / 4) / calc.sqrt(4 * calc.pi),
      style: "dashed", label: $cal(N)(1, 2)$, label-at: 2.6, label-pos: right),
    data(((-2, 0.05), (-1, 0.24), (0, 0.4), (1, 0.24), (2, 0.05)), style: none, marks: "dot"),
    vline(0),
  ),
  caption: [Two densities.],
)
```

Useful typst math for closures: `calc.exp`, `calc.ln`, `calc.log(x, base: 10)`, `calc.pow(x, n)`,
`calc.sqrt`, `calc.sin`, `calc.cos`, `calc.abs`, `calc.max`, `calc.min`, `calc.pi`, `calc.e`.
A sigmoid is `x => 1 / (1 + calc.exp(-x))`; a Gaussian density with mean `m` and standard
deviation `s` is `x => calc.exp(-calc.pow((x - m) / s, 2) / 2) / (s * calc.sqrt(2 * calc.pi))`.
Closures see variables from the surrounding `#let` bindings, so parameters can be defined once
and reused across several `func` items.
