// Exports //
#let make-label
#let make-category
#let with-arrows
#let with-node-spacing

#{
  let context(f) = style(sty => f((
    style: sty,
    measure: (elem) => measure(elem, sty)
  )))

  let getcontent(elem, ctx) = {
    if type(elem) == "content" {
      while true {
        if repr(elem.func()) == "style" {
          elem = (elem.func)(ctx.style)
        // } else if repr(elem.func()) == "locate" {
        //   elem = (elem.func)(ctx.location)
        } else {
          return elem
        }
      }
    } else {
      elem
    }
  }

  let m(elem, ctx) = {
    measure(elem, ctx.style)
  }

  let node-spacing(ctx) = {
    let ns = m(metadata("x-bar-node-spacing"), ctx).width
    if ns == 0pt { 8pt } else { ns }
  }

  // The `dx' value attached via metadata to each node/branch is the amount of horizontal space that the node/branch should be offset. For simple (non-branching) nodes, this is half of the node's width.
  let getdx(x, ctx) = {
    if type(x) == "content" {
      x = getcontent(x, ctx)
      if repr(x.func()) == "sequence" and x.children.first().func() == metadata {
        x.children.first().value.dx
      } else {
        m(x, ctx).width/2
      }
    } else {
      m(x, ctx).width/2
    }
  }

  // The `children' value attached via metadata to each node/branch contains an array of pairs that specify the horizontal and vertical position of each terminal in the tree. This information is used by `with-arrows'.
  let getchildren(x, ctx) = {
    if type(x) == "content" {
      x = getcontent(x, ctx)
      if repr(x.func()) == "sequence" and x.children.first().func() == metadata {
        x.children.first().value.children
      } else {
        ()
      }
    } else {
      ()
    }
  }

  // At each extension of the tree, the positions in the `children' value are updated to account for the horizontal and vertical extension of the tree.
  let updatechildren(children, dx, dy) = {
    children.map(c => (c.at(0), (c.at(1).at(0)+dx, c.at(1).at(1)+dy)))
  }

  // Place `label' above `term'. If `term' is content returned by `node' or `branch', then position it correctly according to the attached metadata.
  let node(label, ..term) = {
    let max(a, b) = if a > b { a } else { b }

    if term.pos().len() == 0 {
      label
    } else {
      let term = term.pos().first()
      context(ctx => {
        let tdx = getdx(term, ctx)
        let width = max(m(label, ctx).width, m(term, ctx).width)
        let (labeloffset, termoffset) = (0pt, 0pt)
        if tdx < m(label, ctx).width/2 {
          termoffset = m(label, ctx).width/2 - tdx
        } else {
          labeloffset = tdx - m(label, ctx).width/2
        }
        metadata((
          dx: labeloffset + m(label, ctx).width/2,
          children: updatechildren(getchildren(term, ctx), termoffset, m(label, ctx).height+3pt)))
        stack(
          dir: ttb, spacing: 3pt,
          move(dx: labeloffset, label),
          move(dx: termoffset, getcontent(term, ctx)))
      })
    }
  }

  // https://github.com/typst/typst/issues/2196#issuecomment-1728135476
  let to-string(content) = {
    if content.has("text") {
      content.text
    } else if content.has("children") {
      content.children.map(to-string).join("")
    } else if content.has("body") {
      to-string(content.body)
    } else if content == [ ] {
      " "
    }
  }

  // Create a unary or binary branch between given `terms'.
  let branch(..terms) = context(ctx => {
    if terms.pos().len() == 1 {
      let term = terms.pos().first()
      if term == [] { term = "" }

      let s = if type(term) == str {
        term
      } else if type(term) == content {
        to-string(getcontent(term, ctx))
      } else {
        ""
      }

      let roof = s.match(regex(" ")) != none
      let tdx = getdx(term, ctx)
      metadata((dx: tdx, children: ((term, (m(term, ctx).width/2, 3pt+12pt+m(term, ctx).height)),)))
      stack(dir: ttb, spacing: 3pt,
        if term != "" {
          if roof {
            polygon(stroke: 0.5pt, (0pt, 12pt), (tdx, 0pt), (tdx*2, 12pt))
          } else {
            move(dx: tdx - 0.5pt,
              line(stroke: 0.5pt, length: 12pt, angle: 90deg))
          }
        },
        getcontent(term, ctx))
    } else if terms.pos().len() >= 2 {
      let (left, right) = terms.pos()
      let leftwidth = m(left, ctx).width
      let rightwidth = m(right, ctx).width
      let width = leftwidth + rightwidth + node-spacing(ctx)
      let leftdx = getdx(left, ctx)
      let rightdx = getdx(right, ctx)
      let bottom = stack(dir: ltr, spacing: node-spacing(ctx), getcontent(left, ctx), getcontent(right, ctx))
      let labelmid = leftdx + ((width - rightwidth + rightdx) - leftdx)/2
      let top = stack(dir: ltr,
        line(stroke: 0.5pt, start: (leftdx, 12pt), end: (labelmid,0pt)),
        line(stroke: 0.5pt, start: (labelmid - leftdx, 12pt), end: (0pt,0pt)))
      metadata((
        dx: labelmid,
        children: updatechildren(getchildren(left, ctx), 0pt, 12pt+3pt)
          + updatechildren(getchildren(right, ctx), leftwidth+node-spacing(ctx), 12pt+3pt)))
      stack(dir: ttb, spacing: 3pt, top, bottom)
    }
  })

  // Using the `children' value, return the terminal in `tree' that is equal to `term'. This is used by `with-arrows'.
  let getchild(tree, term, ctx) = {
    let children = getcontent(tree, ctx).children.at(0).value.children
    let found
    for child in children {
      if child.first() == term {
        found = child
        break
      }
    }
    if found != none {
      found.at(1)
    }
  }

  // Display `tree' with movement arrows between the terminals specified in `pairs'.
  with-arrows = (tree, ..pairs) => context(ctx => {
    let pairs = pairs.pos()
    let lowest = 0pt
    for pair in pairs {
      let (d, t) = pair.map(term => getchild(tree, term, ctx))
      if d.at(0) > t.at(0) {
        let tmp = d
        d = t
        t = tmp
      }
      let p = path(stroke: 0.5pt,
        ((d.at(0), d.at(1) + 4pt), (0pt, -(t.at(1)-d.at(1)))),
        ((t.at(0), t.at(1) + 4pt), (-(t.at(1)-d.at(1))/3, 36pt)))
      place(p)
      let (w, h) = (3pt, 4pt)
      place(dx: d.at(0), dy: d.at(1) + 4pt,
        polygon(fill: black, stroke: 0.5pt,
          (-w/2, h), (0pt, 0pt), (w/2, h)))
      let low = m(p, ctx).height
      if low > lowest { lowest = low }
    }
    getcontent(tree, ctx)
    let diff = lowest - m(tree, ctx).height
    if diff > 0pt { v(diff) }
  })

  with-node-spacing = (ns, body) => {
    show metadata.where(value: "x-bar-node-spacing"): h(ns)
    body
  }

  // Curry `node' with `label'.
  make-label = (label) => (..rest) => {
    if rest.pos().len() == 0 {
      node(label)
    } else {
      node(label, branch(..rest))
    }
  }

  // Create node functions for `label' at phrase-, bar- and head-level.
  make-category = (label) => (
    make-label(label+"P"), 
    make-label(label+"′"), 
    make-label(label))
}

#let _P = make-label(block(height: -6pt))
#let Spec = make-label("Spec")

#let (AdvP, Adv1, Adv0) = make-category("Adv")
#let (AuxP, Aux1, Aux0) = make-category("Aux")
#let (CP, C1, C0) = make-category("C")
#let (DP, D1, D0) = make-category("D")
#let (FP, F1, F0) = make-category("F")
#let (FinP, Fin1, Fin0) = make-category("Fin")
#let (ForceP, Force1, Force0) = make-category("Force")
#let (IP, I1, I0) = make-category("I")
#let (NP, N1, N0) = make-category("N")
#let (NegP, Neg1, Neg0) = make-category("Neg")
#let (PP, P1, P0) = make-category("P")
#let (PartP, Part1, Part0) = make-category("Part")
#let (TP, T1, T0) = make-category("T")
#let (VP, V1, V0) = make-category("V")
#let (XP, X1, X0) = make-category("X")
#let (vP, v1, v0) = make-category([_v_])
