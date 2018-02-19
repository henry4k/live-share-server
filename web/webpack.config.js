'use strict';

const webpack = require('webpack');
const path = require('path');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const NodeExternals = require('webpack-node-externals');

function relativePath(sub) {
    return path.join(__dirname, sub);
}

const outputPath = relativePath('dist');

module.exports = function(env) {
    const generateSourceMaps = true;
    return [{
        target: 'web',
        node: false,
        devtool: generateSourceMaps ? 'source-map' : '',
        externals: [NodeExternals({
            whitelist: [/^rxjs/]
        })],
        entry: [
            relativePath('src/script/main.js'),
            relativePath('src/index.html')
        ],
        output: {
            path: outputPath,
            filename: 'script.js'
        },
        module: {
            rules: [
                {
                    test: [/\.js$/],
                    loader: 'babel-loader',
                    options: {
                        presets: [['env', {
                            targets: {
                                browsers: ['last 2 versions']
                            }
                        }]]
                    }
                },
                {
                    test: [/\.html$/],
                    use: [
                        {
                            loader: 'file-loader',
                            options: {
                                name: '[name].html'
                            }
                        },
                        {
                            loader: 'extract-loader'
                        },
                        {
                            loader: 'html-loader',
                            options: {
                                attrs: [
                                    'img:src',
                                    'link:href'
                                ]
                            }
                        }
                    ]
                },
                {
                    test: [/\.scss$/],
                    use: [
                        {
                            loader: 'file-loader',
                            options: {
                                name: '[name].css'
                            }
                        },
                        {
                            loader: 'extract-loader'
                        },
                        {
                            loader: 'css-loader',
                            options: {
                                sourceMap: generateSourceMaps,
                                minimize: true
                            }
                        },
                        {
                            loader: 'sass-loader',
                            options: {
                                sourceMap: generateSourceMaps
                            }
                        }
                    ]
                }
            ]
        },
        plugins: [
            new CleanWebpackPlugin([outputPath])
        ]
    }];
};
