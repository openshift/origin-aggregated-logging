# vega-spec-injector

![Node](https://img.shields.io/node/v/vega-spec-injector.svg?style=flat-square)
[![NPM](https://img.shields.io/npm/v/vega-spec-injector.svg?style=flat-square)](https://www.npmjs.com/package/vega-spec-injector)
[![Travis](https://img.shields.io/travis/nyurik/vega-spec-injector/master.svg?style=flat-square)](https://travis-ci.org/nyurik/vega-spec-injector)
[![David](https://img.shields.io/david/nyurik/vega-spec-injector.svg?style=flat-square)](https://david-dm.org/nyurik/vega-spec-injector)
[![Coverage Status](https://img.shields.io/coveralls/nyurik/vega-spec-injector.svg?style=flat-square)](https://coveralls.io/github/nyurik/vega-spec-injector)
[![Gitmoji](https://img.shields.io/badge/gitmoji-%20😜%20😍-FFDD67.svg?style=flat-square)](https://gitmoji.carloscuesta.me/)

> Vega helper library to simplify modification of the Vega and VegaLite JSON before parsing.

### Usage

```js
import vegaSpecInjector from 'vega-spec-injector';

```

### Installation

Install via [yarn](https://github.com/yarnpkg/yarn)

	yarn add vega-spec-injector (--dev)

or npm

	npm install vega-spec-injector (--save-dev)


### configuration

You can pass in extra options as a configuration object (➕ required, ➖ optional, ✏️ default).

```js
import vegaSpecInjector from 'vega-spec-injector';

```

➖ **property** ( type ) ` ✏️ default `
<br/> 📝 description
<br/> ❗️ warning
<br/> ℹ️ info
<br/> 💡 example

### methods

#### #name

```js
vegaSpecInjector

```

### Examples

See [`example`](example/script.js) folder or the [runkit](https://runkit.com/nyurik/vega-spec-injector) example.

### Builds

If you don't use a package manager, you can [access `vega-spec-injector` via unpkg (CDN)](https://unpkg.com/vega-spec-injector/), download the source, or point your package manager to the url.

`vega-spec-injector` is compiled as a collection of [CommonJS](http://webpack.github.io/docs/commonjs.html) modules & [ES2015 modules](http://www.2ality.com/2014/0
  -9/es6-modules-final.html) for bundlers that support the `jsnext:main` or `module` field in package.json (Rollup, Webpack 2)

The `vega-spec-injector` package includes precompiled production and development [UMD](https://github.com/umdjs/umd) builds in the [`dist` folder](https://unpkg.com/vega-spec-injector/dist/). They can be used directly without a bundler and are thus compatible with many popular JavaScript module loaders and environments. You can drop a UMD build as a [`<script>` tag](https://unpkg.com/vega-spec-injector) on your page. The UMD builds make `vega-spec-injector` available as a `window.vegaSpecInjector` global variable.

### License

The code is available under the [MIT](LICENSE) license.

### Contributing

We are open to contributions, see [CONTRIBUTING.md](CONTRIBUTING.md) for more info.

### Misc

This module was created using [generator-module-boilerplate](https://github.com/duivvv/generator-module-boilerplate).
