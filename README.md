# Logic State
<sup>A language for describing a statemachine, a concept to picture the soundness of your system</sup><br>

[![License](https://img.shields.io/github/license/logic-state/logicstate.svg)](./LICENSE)

> 🚧 Still **Experimental** 🏗️

## About
*Logic State* is a language for describing deterministic state machine that later can be used to generate code or just transpile it into another format. This project is more focus on how to describe state machine universally that can be used in another language/platform rather than drawing a diagram. For drawing non_deterministic state machine ([NFA][]), please use specialized drawing-language like [Graphviz][], [Mermaid][], or [State Machine Cat][].

<!-- ![quick_demo](https://user-images.githubusercontent.com/4953069/60861162-a5d1a800-a243-11e9-8dd3-b04ee3fde30c.gif) -->

### Philosophy
- **Readable** just like you read then visualize a state diagram
- **Writeable** just like you write code which is concise, clear, and can be refactored
- **Transferable** to any implementation (e.g platform, programming language, runtime, etc)

## Contributing
[![open "help wanted" issues](https://img.shields.io/github/issues/logic-state/logicstate/help%20wanted.svg)](https://github.com/logic-state/logic-state/labels/help%20wanted)
[![open "good first issue" issues](https://img.shields.io/github/issues/logic-state/logicstate/good%20first%20issue.svg)](https://github.com/logic-state/logic-state/labels/good%20first%20issue)

<!-- TODO: add proper CONTRIBUTING.md alongs with ARCHITECTURE.md and github template for issues & pull_request -->

Any kind of contributions are welcome as long as it follow [Code of Conduct](CODE_OF_CONDUCT.md).<br>

<sup><sup>If anyone have questions or something to discuss, feel free to DM or mention me in any services that have my profile picture 👹.</sup></sup>

## License

This project is licensed under the Universal Permissive License 1.0 - see the [LICENSE](LICENSE) file for more detail.

## Resources

- [*Statecharts in the Making: A Personal Account*](http://www.wisdom.weizmann.ac.il/~harel/papers/Statecharts.History.pdf) by David Harel
- [Welcome to the world of Statecharts](https://statecharts.github.io/)
- [A Practical Guide to State Machines](https://deniskyashif.com/2019/11/20/a-practical-guide-to-state-machines/) - an article more on how to simplify and optimize the statemachine

[NFA]: https://www.tutorialspoint.com/automata_theory/non_deterministic_finite_automaton.htm
[Graphviz]: https://www.graphviz.org/
[PlantUML]: http://plantuml.com/state-diagram
[Mermaid]: https://mermaidjs.github.io/
[State Machine Cat]: https://github.com/sverweij/state-machine-cat
[graph-easy]: https://metacpan.org/pod/distribution/Graph-Easy/bin/graph-easy
[release page]: https://github.com/DrSensor/scdlang/releases
