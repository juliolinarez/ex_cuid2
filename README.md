# ExCuid2

[![Hex.pm](https://img.shields.io/hexpm/v/ex_cuid2.svg)](https://hex.pm/packages/ex_cuid2)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_cuid2/)

**An Elixir implementation of CUID2 (Collision-Resistant Unique Identifiers).**

`ExCuid2` generates secure, collision-resistant unique identifiers designed for efficiency and horizontal scaling. They are an excellent choice for primary keys in distributed databases.

## Features

- **Collision-Resistant:** Uses multiple entropy sources to minimize the probability of collisions, even in high-concurrency systems.
- **Secure:** Starts with a random letter to prevent enumeration attacks and uses `:crypto.strong_rand_bytes` for cryptographically secure entropy.
- **Scalable:** Includes a process fingerprint to ensure uniqueness across different nodes and application restarts.
- **Efficient:** Implemented with a stateful `Agent` to manage an atomic counter quickly and safely.
- **Customizable:** Allows generating IDs with a length between 24 and 32 characters.

## Installation

The package is available in [Hex](https://hex.pm/packages/ex_cuid2) and can be installed by adding `ex_cuid2` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_cuid2, "~> 0.9.0"}
  ]
end
```