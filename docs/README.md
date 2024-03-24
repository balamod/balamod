# Balamod Documentation

Welcome to the official documentation for Balamod, a modloader, decompiler, and code injector for the popular poker game, Balatro.

## Building the Documentation

To build the documentation, you need to have [mdBook](https://rust-lang.github.io/mdBook/index.html) and [mdbook-admonish](https://github.com/tommilligan/mdbook-admonish/) installed on your system. 

You can easily install the `mdbook` and `mdbook-admonish` with Cargo:

```bash
cargo install mdbook mdbook-admonish mdbook-toc
```

Once you have it installed, you can run the following command to build the documentation:

```bash
mdbook build
```

The documentation will be generated in the `book` directory.

Or you can run the following command to serve the documentation locally:

```bash
mdbook serve
```

## Contributing

If you want to contribute to the documentation, you can find the source files in the `src` directory. Feel free to make changes and submit a pull request.
