#import "@preview/cetz:0.5.2"

#set heading(numbering: "1.")
#show heading: it => {
  if it.numbering != none {
    counter(figure.where(kind: raw)).update(0)
  }
  it
}
#show figure: set figure(kind: raw, supplement: [Figure], numbering: num => (counter(heading).get() + (num,))
  .map(str)
  .join("."))
#show figure: set block(spacing: 2em)
#show link: set text(fill: blue)
#show link: underline

#let simlink(code) = { link("http://kendallfrey.com/photon-game/#" + code)[Open in simulator] }

#title("The Photon Game")

= Abstract

The Photon Game is a three-state cellular automaton capable of universal computation with intuitively composable gadgets. The three states represent empty space, photons, and devices. Photons move through space in straight diagonal lines. Devices are static, and only serve to manipulate photons. The only nontrivial interactions are between photons and devices, and in fact all of the nonlinear behaviour arises from a single-cell device, known as the "crystal".

= Introduction

The Photon Game is a block cellular automaton using the Margolus neighbourhood. This means that on every step the grid is divided into 2x2 blocks, and each block is updated as a whole, following the rules in the transition table. On even-numbered steps, the blocks are divided along even-numbered rows and columns, and on odd-numbered steps they are divided along odd-numbered rows and columns. The block transition rules are given by the following table, plus rotation and reflection.

#let pg-grid(w, h, parity, contents, ..args) = {
  let size = args.at("size", default: 10pt)
  let color = (white, rgb("#00cc00"), black)
  let grid-stroke(x, y) = {
    let c = (paint: gray, thickness: 0.5pt)
    let s = (:)
    if calc.rem(x, 2) == parity { s = (..s, left: c) } else { s = (..s, right: c) }
    if calc.rem(y, 2) == parity { s = (..s, top: c) } else { s = (..s, bottom: c) }
    return s
  }
  grid(columns: (size,) * w, rows: (size,) * h, stroke: grid-stroke, fill: (x, y) => color.at(
      contents.at(y, default: ()).at(x, default: 0),
    ))
}

#let transition(from, to) = [
  #box(pg-grid(2, 2, 0, from), baseline: horizon)
  #box([→], baseline: horizon)
  #box(pg-grid(2, 2, 0, to), baseline: horizon)
]

#figure(
  supplement: [Table],
  caption: [Transition table for the Photon Game],
  table(
    columns: 3,
    transition(((0, 0), (0, 0)), ((0, 0), (0, 0))),
    transition(((1, 0), (0, 0)), ((0, 0), (0, 1))),
    transition(((1, 1), (0, 0)), ((0, 0), (1, 1))),

    transition(((1, 0), (0, 1)), ((1, 0), (0, 1))),
    transition(((1, 1), (1, 0)), ((0, 1), (1, 1))),
    transition(((1, 1), (1, 1)), ((1, 1), (1, 1))),

    transition(((2, 0), (0, 0)), ((2, 0), (0, 0))),
    transition(((2, 1), (0, 0)), ((2, 0), (0, 1))),
    transition(((2, 0), (0, 1)), ((2, 0), (0, 0))),

    transition(((2, 1), (1, 0)), ((2, 0), (0, 1))),
    transition(((2, 1), (0, 1)), ((2, 0), (1, 1))),
    transition(((2, 1), (1, 1)), ((2, 1), (1, 0))),

    transition(((2, 2), (0, 0)), ((2, 2), (0, 0))),
    transition(((2, 2), (1, 0)), ((2, 2), (0, 1))),
    transition(((2, 2), (1, 1)), ((2, 2), (1, 1))),

    transition(((2, 0), (0, 2)), ((2, 0), (0, 2))),
    transition(((2, 1), (0, 2)), ((2, 0), (1, 2))),
    transition(((2, 1), (1, 2)), ((2, 1), (1, 2))),

    transition(((2, 2), (2, 0)), ((2, 2), (2, 1))),
    transition(((2, 2), (2, 1)), ((2, 2), (2, 1))),
    transition(((2, 2), (2, 2)), ((2, 2), (2, 2))),
  ),
)

For example, a single step in a larger grid might look like this.

#figure(
  numbering: none,
  [
    #box(
      pg-grid(10, 10, 0, (
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 1, 1, 0, 0),
        (0, 0, 0, 0, 0, 0, 1, 1, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      )),
      baseline: horizon,
    )
    #box([→], baseline: horizon)
    #box(
      pg-grid(10, 10, 0, (
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 1, 1, 0, 0),
        (0, 0, 0, 0, 0, 0, 1, 1, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      )),
      baseline: horizon,
    )
  ],
)

The next step would look like this. Note that the block borders are now aligned with the odd grid.

#figure(
  numbering: none,
  [
    #box(
      pg-grid(10, 10, 1, (
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 1, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 1, 1, 0, 0),
        (0, 0, 0, 0, 0, 0, 1, 1, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      )),
      baseline: horizon,
    )
    #box([→], baseline: horizon)
    #box(
      pg-grid(10, 10, 1, (
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 1, 0, 0, 1, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, 0, 0, 0, 0, 1, 0, 0, 1, 0),
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      )),
      baseline: horizon,
    )
  ],
)

As an example of a circuit that can be built with these rules, here is a clock which emits one photon every 264 steps, expressed as the product of period-22 and period-24 clocks.

#figure(
  caption: [A period-264 clock\ #simlink("data:EACAgAgAyiABAQD9wkggAMoYKCIAyQioIIAA/f3G")],
  pg-grid(18, 18, 0, (
    (0, 0, 0, 0, 0, 2),
    (0, 2, 0, 2),
    (0, 0, 1, 0, 1),
    (2,),
    ..((),) * 6,
    (..(0,) * 15, 2),
    (..(0,) * 15, 1, 2),
    (..(0,) * 13, 2, 0, 2, 2),
    (..(0,) * 12, 1, 0, 2, 0, 2),
    (..(0,) * 11, 2, 0, 2),
    (..(0,) * 12, 2, 2, 2, 0, 0, 2),
  )),
)

There are four fundamental gadgets that can be built in a single 2x2 block. They can be thought of as logic gates with inputs and outputs on the open corners. They may also be drawn as symbols on schematic diagrams. All possible gadgets can be expressed as combinations of the fundamental gadgets.

#let schematic() = cetz.draw.scale(x: 1.5, y: -1.5)

// https://github.com/cetz-package/cetz/issues/1032
#let content-fixed(..args) = {
  return (
    ctx => {
      let angle = if type(args.angle) != std.angle {
        let (_, a) = cetz.coordinate.resolve(ctx, args.at(0))
        let (_, c) = cetz.coordinate.resolve(ctx, args.angle)
        cetz.vector.angle2(cetz.util.apply-transform(ctx.transform, a), cetz.util.apply-transform(ctx.transform, c))
      } else {
        args.angle
      }
      cetz.draw.content(..args, angle: angle).at(0)(ctx)
    },
  )
}

#let beam(p1, p2, ..args) = {
  import cetz.draw: anchor, group, line, set-style
  group(name: args.at("name", default: none), {
    let mark = (end: ">>", length: 0.1, offset: 0.05)
    set-style(padding: 0.15, mark: mark)

    let label1 = args.at(0, default: none)
    let stroke1 = if type(label1) == content { (dash: "densely-dashed") } else { auto }

    let label2 = args.at(1, default: none)
    let stroke2 = if type(label2) == content { (dash: "densely-dashed") } else { auto }

    if label1 != none and label2 != none {
      set-style(mark: (..mark, harpoon: true, flip: true))
      line((p1, 0.05, 90deg, p2), (p2, 0.05, -90deg, p1), name: "line1", stroke: stroke1)
      line((p2, 0.05, 90deg, p1), (p1, 0.05, -90deg, p2), name: "line2", stroke: stroke2)
      if type(label1) == content {
        content-fixed("line1", anchor: "north", angle: "line1.end", label1)
      }
      if type(label2) == content {
        content-fixed("line2", anchor: "south", angle: "line2.start", label2)
      }
    } else if label1 != none {
      line(p1, p2, name: "line", stroke: stroke1)
      if type(label1) == content {
        content-fixed("line", anchor: "north", angle: "line.end", label1)
      }
    } else if label2 != none {
      line(p2, p1, name: "line", stroke: stroke2)
      if type(label2) == content {
        content-fixed("line", anchor: "south", angle: "line.start", label2)
      }
    }

    anchor("default", (p1, 50%, p2))
    anchor("s", p1)
    anchor("e", p2)
  })
}

#let mirror(p, angle, ..args) = {
  import cetz.draw: *
  group(..args, {
    translate(p)
    rotate(angle * 90deg + 45deg)
    line((-0.25, 0.25), (0.25, 0.25), (0.25, -0.25), close: true)
    anchor("l", (0.25, 0))
    anchor("r", (0, 0.25))
  })
}

#let source(p, angle, ..args) = {
  import cetz.draw: *
  group(..args, {
    translate(p)
    rotate(angle * 90deg + 45deg)
    line((-0.25, -0.15), (0.25, -0.15), (0.25, 0.15), (-0.25, 0.15), close: true)
    line((0.15, -0.15), (0.15, 0.15))
    anchor("f", (0.25, 0))
  })
}

#let crystal(p, angle, ..args) = {
  import cetz.draw: *
  group(..args, {
    translate(p)
    rotate(angle * 90deg + 45deg)
    line((-0.25, -0.25), (0.25, -0.25), (0.25, 0.25), (-0.25, 0.25), close: true)
    anchor("l", (0, -0.25))
    anchor("r", (0, 0.25))
    anchor("f", (0.25, 0))
    line((-0.25, -0.25), (0, 0), (-0.25, 0.25))
  })
}

#heading(level: 2, numbering: none)[Channel]

The "channel" gadget has two diagonally opposite open corners and simply transmits signals through from one to the other. It has no utility by itself, but may occur inside compact gadgets.

#figure(
  caption: [The channel gadget\ #simlink("data:CAAAywQAyYAAxBACAMIQAMoQAMQ=")],
  pg-grid(2, 2, 0, ((2, 0), (0, 2))),
)

#heading(level: 2, numbering: none)[Mirror]

The "mirror" gadget is the same as the channel except the open corners are adjacent, and therefore it redirects signals through 90 degrees. It has no computational purpose but can be used for routing signals.

#figure(
  caption: [The mirror gadget and symbol\ #simlink("data:CAAAwIAgAMoQAMhAABAA3A==")],
  {
    pg-grid(2, 2, 0, ((2, 2),))
    cetz.canvas({
      import cetz.draw: *
      schematic()

      mirror((1, 0), 0, name: "a")
      beam((0, 1), "a.r", [], [])
      beam("a.l", (2, 1), [], [])
    })
  },
)

#heading(level: 2, numbering: none)[Source]

The "source" gadget produces a steady stream of photons from its single open corner. It is the only mechanism by which the number of photons in the system can increase.

#figure(
  caption: [The source gadget and symbol\ #simlink("data:CACAIADDCAD0")],
  {
    pg-grid(2, 2, 0, ((2, 2), (2, 0)))
    cetz.canvas({
      import cetz.draw: *
      schematic()

      source((0, 0), 0, name: "a")
      beam("a.f", (1, 1), 1)
    })
  },
)

#heading(level: 2, numbering: none)[Crystal]

The "crystal" gadget is by far the most interesting of the fundamental gadgets. It is essentially a logic gate with three inputs and three outputs. Various fundamental logic gates can be created by tying inputs to low (no photons) or high (a constant stream of photons), analogous to how a NOT gate can be implemented with a NAND gate by tying one input to high. The crystal will be discussed in more detail later.

#figure(
  caption: [The crystal gadget and symbol\ #simlink("data:CAAA2IAEAMMQAMZAAMAQAMMQAMNA")],
  {
    pg-grid(2, 2, 0, ((2,),))
    cetz.canvas({
      import cetz.draw: *
      schematic()

      crystal((1, 1), 0, name: "a")
      beam((2, 0), "a.l", [], [])
      beam((0, 2), "a.r", [], [])
      beam("a.f", (2, 2), [], [])
    })
  },
)

= Elementary Gadgets

Deriving a universal set of logic gates from the fundamental gadgets is a stimulating exercise. Curious readers are encouraged to try this for themselves before reading this section. See #link(<crystal-functions>)[Crystal Functions] in the appendix for a useful reference.

#heading(level: 2, numbering: none)[OR gate]

An OR gate can be directly implemented with a single crystal.

#figure(
  caption: [OR gate schematic\ #simlink("data:CAAAxAQA0IAEAMoQAMoQAMQ=")],
  cetz.canvas({
    import cetz.draw: *
    schematic()

    crystal((1, 1), 0, name: "a")
    beam((0, 2), "a.r", [A])
    beam("a.l", (2, 0), none, [B])
    beam("a.f", (2, 2), [A ∨ B])
  }),
)

#heading(level: 2, numbering: none)[Beam dump]

The crystal can function as a "beam dump", absorbing a signal without reflection.

#figure(
  caption: [Beam dump schematic\ #simlink("data:CAABAMUBANcBANcC")],
  cetz.canvas({
    import cetz.draw: *
    schematic()

    crystal((1, 1), 2, name: "a")
    beam((0, 0), "a.f", [A])
  }),
)

#heading(level: 2, numbering: none)[Diode]

A "diode" can absorb a signal from one direction while passing a signal from the other direction.

#figure(
  caption: [Diode schematic\ #simlink("data:CAAA2IAIAMMQAMZAAMAQAMFAABAAxA==")],
  cetz.canvas({
    import cetz.draw: *
    schematic()

    crystal((1, 1), 0, name: "a")
    crystal((2, 0), 1, name: "b")
    beam((0, 2), "a.r", [A])
    beam("a.l", "b.f", [A ∧ B])
    beam("a.f", (2, 2), [A], [B])
  }),
)

#heading(level: 2, numbering: none)[AND gate]

An AND gate uses a diode to absorb a duplicate signal.

#figure(
  caption: [AND gate schematic\ #simlink("data:CAABAQDFAQDNAQAgAMMggADX")],
  cetz.canvas({
    import cetz.draw: *
    schematic()

    crystal((1, 2), 3, name: "a")
    crystal((2, 1), 1, name: "b")
    crystal((3, 2), 2, name: "c")
    beam((0, 1), "a.l", [A])
    beam((1, 0), "b.r", [B])
    beam("a.f", "b.f", [A], [B])
    beam("b.l", "c.f", [A ∧ B])
    beam("a.r", (2, 3), [A ∧ B])
  }),
)

#heading(level: 2, numbering: none)[Injector]

An "injector" can send a constant high signal into the data output of another gadget. This is an important component of logic gates that require a constant incoming stream of photons from the same direction that the output is emitted.

#figure(
  caption: [Injector schematic\ #simlink("data:CAAA2CogAMMEAMMEAMMUAMMEAMQ=")],
  cetz.canvas({
    import cetz.draw: *
    schematic()

    crystal((1, 1), 1, name: "a")
    source((0, 0), 0, name: "b")
    beam((0, 2), "a.f", [A], 1)
    beam("b.f", "a.r", 1)
    beam("a.l", (2, 2), [A])
  }),
)

#heading(level: 2, numbering: none)[NOT gate]

A NOT gate requires a little more gadgetry to implement, including a diode and an injector.

#figure(
  caption: [NOT gate schematic\ #simlink("data:CAAA2IAgAMKAGAkAwhBlIADBEAAIAgDAEADE")],
  cetz.canvas({
    import cetz.draw: *
    schematic()

    crystal((1, 1), 0, name: "a")
    crystal((2, 0), 1, name: "b")
    crystal((3, 3), 3, name: "c")
    source((4, 4), 2, name: "d")
    crystal((4, 2), 1, name: "e")
    source((3, 1), 0, name: "f")
    beam((0, 2), "a.r", [A])
    beam("a.l", "b.f", [A])
    beam("a.f", "c.l", [A], 1)
    beam("c.r", "d.f", [A], 1)
    beam("c.f", "e.f", [¬A], 1)
    beam("f.f", "e.r", 1)
    beam("e.l", (5, 3), [¬A])
  }),
)

= Conway's Game of Life

The Game of Life can be simulated in the Photon Game: #simlink("url:http://kendallfrey.com/photon-game/lifegrid.png")

The Life cell takes in 8 inputs from the surrounding cells, aggregates them with a unary counter circuit that saturates at 4, and then computes the next state of the cell as $"alive"(n+1) := ("atleast3" ∨ ("atleast2" ∧ "alive"(n))) ∧ ¬"atleast4"$. The current state of the cell is stored in a latch gadget which is updated every 608 steps by a pulse from a timer.

#pagebreak()

= Appendix

== Crystal Functions <crystal-functions>

This is an exhaustive list containing all permutations of data and constant signals that can be applied to the crystal.

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((2, 2), "a.f", 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam("a.f", (2, 2), none, [A])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", 1)
  beam("a.f", (2, 2), 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", 1)
  beam("a.l", (2, 0), 1)
  beam((2, 2), "a.f", 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", 1)
  beam("a.l", (2, 0), [A])
  beam("a.f", (2, 2), 1, [A])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", 1)
  beam((2, 0), "a.l", 1)
  beam("a.f", (2, 2), 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", 1, 1)
  beam((2, 0), "a.l", 1, 1)
  beam((2, 2), "a.f", 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", 1, [A])
  beam("a.l", (2, 0), [A], 1)
  beam("a.f", (2, 2), [¬A], [A])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A])
  beam("a.f", (2, 2), [A])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A])
  beam("a.l", (2, 0), [A])
  beam("a.f", (2, 2), [A], 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A])
  beam("a.l", (2, 0), [A ∧ B])
  beam("a.f", (2, 2), [A], [B])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A])
  beam((2, 0), "a.l", 1)
  beam("a.f", (2, 2), 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A], 1)
  beam("a.l", (2, 0), [A], 1)
  beam("a.f", (2, 2), [¬A], 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A], [B])
  beam("a.l", (2, 0), [A ∧ B], 1)
  beam("a.f", (2, 2), [¬(A ∧ B)], [B])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A])
  beam("a.l", (2, 0), none, [B])
  beam("a.f", (2, 2), [A ∨ B])
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A], [B])
  beam("a.l", (2, 0), [A], [B])
  beam("a.f", (2, 2), [A ⊕ B], 1)
}))

#figure(cetz.canvas({
  import cetz.draw: *
  schematic()

  crystal((1, 1), 0, name: "a")
  beam((0, 2), "a.r", [A], [B ∧ C])
  beam("a.l", (2, 0), [A ∧ C], [B])
  beam("a.f", (3, 3), [(A ∨ B) ∧ ¬(A ∧ B ∧ C)], [C])
}))
