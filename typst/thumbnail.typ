#let color_primary = rgb("#D0BCFF")
#let color_on_primary = rgb("#381E72")

#let color_surface = rgb("#141218")

// At the default 144ppi, and 72pt = 1in, results in a mapping of 72pt = 144px -> 1pt = 2px.
// The recommended size for opengraph thumbnails is 1200px/630px, which is halved when using pt.
#set page(width: 600pt, height: 315pt, fill: color_surface)
#set text(font: "Roboto Mono")

#align(horizon)[
  #text(fill: color_primary, size: 2em, weight: "regular")[
    > tomerhanochi.com
  ]

  #rect(fill: color_primary, inset: 1.5em, radius: 1em, width: 100%)[
    #align(center)[
      #text(fill: color_on_primary, size: 3em, weight: "regular")[
        #sys.inputs.title
      ]
    ]
  ]
]
