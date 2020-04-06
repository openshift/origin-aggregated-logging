var path = require('path');

module.exports = {
  devtool: 'source-map',

  entry: {
    guide: './src/guide/index.js'
  },

  output: {
    path: path.resolve(__dirname, 'public'),
    filename: 'bundle.js'
  },

  resolve: {
    root: [
      path.resolve(__dirname, 'src')
    ]
  },

  module: {
    loaders: [{
      test: /\.jsx?$/,
      loader: 'babel',
      query: {
        presets: ['es2015', 'react']
      },
      exclude: /node_modules/
    }, {
      test: /\.scss$/,
      loaders: ['style', 'css', 'sass'],
      exclude: /node_modules/
    }, {
      test: /\.html$/,
      loader: 'html',
      exclude: /node_modules/
    }, {
      test: require.resolve('jquery'),
      loader: 'expose?jQuery!expose?$'
    }]
  }
};
