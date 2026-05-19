#set page(
  width: 16cm,
  height: auto,
  margin: (x: 1.5cm, top: 1.2cm, bottom: 1.8cm),
  fill: rgb("#F8F3E1"),
)
#set text(size: 11.5pt, fill: rgb("#41431B"))
#set par(leading: 0.75em, justify: true)

The word _marginalia_ comes from the Latin _margo_ (margin). Scholars filled manuscript margins with commentary, corrections, and doodles — a parallel conversation alongside the main text. This is that.

#v(1.2em)
#line(length: 100%, stroke: (paint: rgb("#E3DBBB"), thickness: 0.8pt))
#v(1.2em)

*A note on curvature.* Let $gamma: [0, 1] -> RR^2$ be a smooth planar curve. The signed curvature is:

$
kappa = (x' y'' - y' x'') / (x'^2 + y'^2)^(3/2)
$

For a circle of radius $r$ — parameterized as $gamma(t) = (r cos t, r sin t)$ — direct computation gives the constant $kappa = 1 slash r$. Smaller circle, sharper turn.

#v(1em)

#align(center)[
  #image(bytes(
    "<svg viewBox='-3.2 -3.2 6.4 6.4' width='180' height='180' xmlns='http://www.w3.org/2000/svg'>"
    + "<line x1='-2.9' y1='0' x2='2.9' y2='0' stroke='#C8C8AA' stroke-width='0.07'/>"
    + "<line x1='0' y1='-2.9' x2='0' y2='2.9' stroke='#C8C8AA' stroke-width='0.07'/>"
    + "<circle cx='0' cy='0' r='2' fill='none' stroke='#AEB784' stroke-width='0.19'/>"
    + "<line x1='0' y1='0' x2='1.414' y2='-1.414' stroke='#41431B' stroke-width='0.13'/>"
    + "<path d='M 0.65 0 A 0.65 0.65 0 0 0 0.46 -0.46' fill='none' stroke='#AEB784' stroke-width='0.11'/>"
    + "<circle cx='0' cy='0' r='0.09' fill='#41431B'/>"
    + "<text x='0.72' y='-0.12' font-size='0.42' fill='#41431B' font-style='italic' font-family='Georgia'>&#x03B8;</text>"
    + "<text x='0.5' y='-0.86' font-size='0.42' fill='#41431B' font-style='italic' font-family='Georgia'>r</text>"
    + "<text x='2.5' y='0.18' font-size='0.36' fill='#AAAAAA' font-style='italic' font-family='Georgia'>x</text>"
    + "<text x='0.12' y='-2.52' font-size='0.36' fill='#AAAAAA' font-style='italic' font-family='Georgia'>y</text>"
    + "</svg>"
  ))
]

#v(0.5em)
#align(center)[
  #text(size: 9pt, fill: rgb("#888866"))[
    _A circle of radius $r$ has constant curvature $kappa = 1 slash r$._
  ]
]

#v(1.5em)
#line(length: 100%, stroke: (paint: rgb("#E3DBBB"), thickness: 0.8pt))
#v(1.2em)

*Taylor's theorem* gives a local polynomial approximation of any smooth $f: RR -> RR$ around $x_0$:

$
f(x) = sum_(n=0)^(N) (f^((n))(x_0))/(n!) (x - x_0)^n + R_N(x)
$

where $R_N(x) = O((x - x_0)^(N+1))$ as $x -> x_0$. The curvature formula above is a geometric instance of this: the osculating circle is the second-order fit to the curve at any point.
