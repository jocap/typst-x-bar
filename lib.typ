// Exports //
#let make-label
#let make-category
#let with-arrows
#let with-node-spacing

#{
  let node-spacing(sty) = {
    let ns = measure(metadata("x-bar-node-spacing"), sty).width
    if ns == 0pt {
        0.7*measure(block(height: 1em), sty).height
      } else {
        ns
    }
  }

  // The `dx' value attached via metadata to each node/branch is the amount of horizontal space that the node/branch should be offset. For simple (non-branching) nodes, this is half of the node's width.
  let getdx(x, sty) = {
    if type(x) == "content" {
      x = if repr(x.func()) == "style" { (x.func)(sty) } else { x }
      if repr(x.func()) == "sequence" and x.children.first().func() == metadata {
        x.children.first().value.dx
      } else {
        measure(x, sty).width/2
      }
    } else {
      measure(x, sty).width/2
    }
  }

  // The `children' value attached via metadata to each node/branch contains an array of pairs that specify the horizontal and vertical position of each terminal in the tree. This information is used by `with-arrows'.
  let getchildren(x, sty) = {
    if type(x) == "content" {
      x = if repr(x.func()) == "style" { (x.func)(sty) } else { x }
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
  let node(label, term, i: none) = {
    let max(a, b) = if a > b { a } else { b }
    if i != none { label = label + sub(i) }

    if term == none {
      label
    } else {
      style(sty => {
        let tdx = getdx(term, sty)
        let width = max(measure(label, sty).width, measure(term, sty).width)
        let (labeloffset, termoffset) = (0pt, 0pt)
        if tdx < measure(label, sty).width/2 {
          termoffset = measure(label, sty).width/2 - tdx
        } else {
          labeloffset = tdx - measure(label, sty).width/2
        }
        let children = updatechildren(getchildren(term, sty), termoffset, measure(label, sty).height+0.27em)
        metadata((
          dx: labeloffset + measure(label, sty).width/2,
          children: children))
        stack(
          dir: ttb, spacing: 0.27em,
          move(dx: labeloffset, label),
          move(dx: termoffset, term))
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
  let branch(..terms) = style(sty => {
    if terms.pos().len() == 1 {
      let term = terms.pos().first()
      if term == [] { term = "" }

      let s = if type(term) == str {
        term
      } else if type(term) == content {
        to-string(if repr(term.func()) == "style" { (term.func)(sty) } else { term })
      } else {
        ""
      }

      let roof = s.match(regex(" ")) != none
      let tdx = getdx(term, sty)
      let children = getchildren(term, sty)
      if children == () {
        children = ((term, (measure(term, sty).width/2, 0.27em+1em+measure(term, sty).height)),)
      } else {
        children = updatechildren(getchildren(term, sty), 0pt, 1em+0.27em)
      }
      metadata((dx: tdx, children: children))
      stack(dir: ttb, spacing: 0.27em,
        if term != "" {
          if roof {
            polygon(stroke: 0.5pt, (0pt, 1em), (tdx, 0pt), (tdx*2, 1em))
          } else {
            move(dx: tdx - 0.5pt,
              line(stroke: 0.5pt, length: 1em, angle: 90deg))
          }
        },
        term)
    } else if terms.pos().len() == 2 {
      let (left, right) = terms.pos()
      let leftwidth = measure(left, sty).width
      let rightwidth = measure(right, sty).width
      let width = leftwidth + rightwidth + node-spacing(sty)
      let leftdx = getdx(left, sty)
      let rightdx = getdx(right, sty)
      let bottom = stack(dir: ltr, spacing: node-spacing(sty), left, right)
      let labelmid = leftdx + ((width - rightwidth + rightdx) - leftdx)/2
      let top = stack(dir: ltr,
        line(stroke: 0.5pt, start: (leftdx, 1em), end: (labelmid,0pt)),
        line(stroke: 0.5pt, start: (labelmid - leftdx, 1em), end: (0pt,0pt)))
      metadata((
        dx: labelmid,
        children: updatechildren(getchildren(left, sty), 0pt, 1em+0.27em)
          + updatechildren(getchildren(right, sty), leftwidth+node-spacing(sty), 1em+0.27em)))
      stack(dir: ttb, spacing: 0.27em, top, bottom)
    } else {
      panic("x-bar/branch: only unary/binary branches supported")
    }
  })

  // Using the `children' value, return the terminal in `tree' that is equal to `term'. This is used by `with-arrows'.
  let getchild(tree, term, sty) = {
    let children = (tree.func)(sty).children.at(0).value.children
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
  with-arrows = (tree, ..pairs) => style(sty => {
    let pairs = pairs.pos()
    let lowest = 0pt
    let ys = ()
    for pair in pairs {
      let (d, t) = pair.map(term => {
        let pos = getchild(tree, term, sty)
        if pos == none {
          panic("x-bar/with-arrows: could not find terminal " + repr(term))
        }
        pos
    })
      if d.at(0) > t.at(0) {
        let tmp = d
        d = t
        t = tmp
      }
      d.at(1) = d.at(1) + 0.36em
      t.at(1) = t.at(1) + 0.36em
      let y = t.at(1) + 1em
      while y in ys { y = y + 1em }
      ys.push(y)
      let p = path(stroke: (thickness: 0.5pt),
        (d.at(0), d.at(1)),
        (d.at(0), y),
        (t.at(0), y),
        (t.at(0), t.at(1)))
      place(p)
      let (w, h) = (0.27em, 0.36em)
      place(dx: d.at(0), dy: d.at(1),
        polygon(fill: black, stroke: 0.5pt,
          (-w/2, h), (0pt, 0pt), (w/2, h)))
      let low = measure(p, sty).height
      if low > lowest { lowest = low }
    }
    tree
    let diff = lowest - measure(tree, sty).height
    if diff > 0pt { v(diff) }
  })

  with-node-spacing = (ns, body) => {
    show metadata.where(value: "x-bar-node-spacing"): h(ns)
    body
  }

  // Curry `node' with `label'.
  make-label = (label) => (..rest) => {
    if rest.pos().len() == 0 {
      node(label, none, ..rest.named())
    } else {
      node(label, branch(..rest), ..rest.named())
    }
  }

  // Create node functions for `label' at phrase-, bar- and head-level.
  make-category = (label) => (
    make-label(label+"P"),
    make-label(label+"′"),
    make-label(label))
}

#let _P = make-label(block(height: -0.53em))
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
#let (AP, A1, A0) = make-category("A")
#let (NegP, Neg1, Neg0) = make-category("Neg")
#let (PP, P1, P0) = make-category("P")
#let (PartP, Part1, Part0) = make-category("Part")
#let (TP, T1, T0) = make-category("T")
#let (VP, V1, V0) = make-category("V")
#let (XP, X1, X0) = make-category("X")
#let (vP, v1, v0) = make-category([_v_])
