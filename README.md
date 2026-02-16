# Objenealogist

> object + genealogist -> objenealogist

A Ruby gem that visualizes class inheritance hierarchy and included modules in a tree format.

## Installation

```bash
gem install objenealogist
```

## Usage

```ruby
require 'objenealogist'

puts Objenealogist.to_tree(MyClass)
```

### Options

- `show_methods`: Show public methods for each class/module (default: `true`)
- `show_locations`: Show source file locations (default: `true`). You can also pass a `Regexp` to show locations only for matching class/module names.

### Example

```
Objenealogist.to_tree(MyClass, show_locations: false)
```

```
C MyClass
│ ├ c
│ └ singleton_c
│
├── M M2
│ └ m2
│
├── M M1
│ └ m1
│
└── C NS::C2
    │ └ c2
    │
    ├── M M4
    │ └ m4
    │
    ├── M M3
    │ └ m3
    │
    └── C C1
        │ └ c1
        │
        ├── M M5
        │ └ m5
        │
        └── C Object
            ├── M Kernel
            └── C BasicObject
```

## License

MIT License
