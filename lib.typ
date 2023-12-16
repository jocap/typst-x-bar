#let max(a, b) = if a > b { a } else { b }

// The `dx' value attached via metadata to each node/branch is the amount of horizontal space that the node/branch should be offset. For simple (non-branching) nodes, this is half of the node's width.
#let getdx(x, sty) = {
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

#let node(label, ..term) = {
  if term.pos().len() == 0 {
    label
  } else {
    let term = term.pos().first()
    style(sty => {
      let tdx = getdx(term, sty)
      let width = max(measure(label, sty).width, measure(term, sty).width)
      let (labeloffset, termoffset) = (0pt, 0pt)
      if tdx < measure(label, sty).width/2 {
        termoffset = measure(label, sty).width/2 - tdx
      } else {
        labeloffset = tdx - measure(label, sty).width/2
      }
      metadata((dx: labeloffset + measure(label, sty).width/2))
      stack(
        dir: ttb, spacing: 3pt,
        move(dx: labeloffset, label),
        move(dx: termoffset, term))
    })
  }
}

#let branch(..terms) = style(sty => {
  if terms.pos().len() == 1 {
    let term = terms.pos().first()
    let tdx = getdx(term, sty)
    metadata((dx: tdx))
    stack(dir: ttb, spacing: 3pt,
      if term != "" {
        move(dx: tdx - 0.5pt,
          line(stroke: 0.5pt, length: 12pt, angle: 90deg))
      },
      term)
  } else if terms.pos().len() >= 2 {
    let (left, right) = terms.pos()
    let leftwidth = measure(left, sty).width
    let rightwidth = measure(right, sty).width
    let width = leftwidth + rightwidth + 6pt
    let leftdx = getdx(left, sty)
    let rightdx = getdx(right, sty)
    let bottom = stack(dir: ltr, spacing: 6pt,
      move(left),
      move(right))
    let labelmid = leftdx + ((width - rightwidth + rightdx) - leftdx)/2
    let top = stack(dir: ltr,
      line(stroke: 0.5pt, start: (leftdx, 12pt), end: (labelmid,0pt)),
      line(stroke: 0.5pt, start: (labelmid - leftdx, 12pt), end: (0pt,0pt)))
    metadata((dx: labelmid))
    stack(dir: ttb, spacing: 3pt, top, bottom)
  }
})

#let bar = text("′", font: "TeX Gyre Termes Math")
#let nodef(label) = (..rest) => {
  if rest.pos().len() == 0 {
    node(label)
  } else {
    node(label, branch(..rest))
  }
}

#let vP = nodef([_v_\P])
#let v- = nodef([_v_#bar])
#let v0 = nodef([_v_])

#let XP = nodef("XP")
#let X- = nodef("X"+bar)
#let X0 = nodef("X")
#let FP = nodef("FP")
#let F- = nodef("F"+bar)
#let F0 = nodef("F")
#let VP = nodef("VP")
#let V- = nodef("V"+bar)
#let V0 = nodef("V")
#let AuxP = nodef("AuxP")
#let Aux- = nodef("Aux"+bar)
#let Aux0 = nodef("Aux")
#let NegP = nodef("NegP")
#let Neg- = nodef("Neg"+bar)
#let Neg0 = nodef("Neg")
#let AdvP = nodef("AdvP")
#let Adv- = nodef("Adv"+bar)
#let Adv0 = nodef("Adv")
#let PartP = nodef("PartP")
#let Part- = nodef("Part"+bar)
#let Part0 = nodef("Part")
#let NP = nodef("NP")
#let N- = nodef("N"+bar)
#let N0 = nodef("N")
#let DP = nodef("DP")
#let D- = nodef("D"+bar)
#let D0 = nodef("D")
#let PP = nodef("PP")
#let P- = nodef("P"+bar)
#let P0 = nodef("P")
#let IP = nodef("IP")
#let I- = nodef("I"+bar)
#let I0 = nodef("I")
#let TP = nodef("TP")
#let T- = nodef("T"+bar)
#let T0 = nodef("T")
#let CP = nodef("CP")
#let C- = nodef("C"+bar)
#let C0 = nodef("C")
#let Spec = nodef("Spec")
