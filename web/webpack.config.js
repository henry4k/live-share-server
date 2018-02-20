'use strict';

const webpack = require('webpack');
const path = require('path');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const NodeExternals = require('webpack-node-externals');
const AutoDllPlugin = require('autodll-webpack-plugin');
const ExtractTextPlugin = require("extract-text-webpack-plugin");

function relativePath(sub) {
    return path.resolve(__dirname, sub);
}

const nodeLibs = ['rxjs', 'immutable'];
const outputPath = relativePath('dist');
const generateSourceMaps = true;
const minimize = true;

const minimizePlugins = [];
if(minimize)
    minimizePlugins.push(new webpack.optimize.UglifyJsPlugin({
        sourceMap: generateSourceMaps
    }));

const extractCssPlugin = new ExtractTextPlugin({
    filename: 'style.css'
});

module.exports = function(env) {
    return [{
        context: path.resolve(__dirname),
        target: 'web',
        node: false,
        devtool: generateSourceMaps ? 'source-map' : '',
        watchOptions: {
            ignored: relativePath('node_modules')
        },
        externals: [
            NodeExternals({
                whitelist: nodeLibs.map(name => new RegExp('^'+name))
            })
        ],
        entry: [
            relativePath('src/script/main.js'),
            relativePath('src/index.html'),
            relativePath('src/style.scss')
        ],
        output: {
            path: outputPath,
            filename: 'script.js'
            //publicPath: '/'
        },
        module: {
            rules: [
                {
                    test: [/\.js$/],
                    loader: 'babel-loader',
                    include: relativePath('src/script'),
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
                                name: '[name].[ext]'
                            }
                        },
                        {
                            loader: 'extract-loader'
                        },
                        {
                            loader: 'html-loader',
                            options: {
                                minimize: minimize,
                                attrs: [
                                    'img:src'
                                ]
                            }
                        }
                    ]
                },
                {
                    test: [/\.scss$/],
                    use: extractCssPlugin.extract({
                        fallback: 'style-loader',
                        use: [
                            {
                                loader: 'css-loader',
                                options: {
                                    sourceMap: generateSourceMaps,
                                    minimize: minimize
                                }
                            },
                            {
                                loader: 'sass-loader',
                                options: {
                                    sourceMap: generateSourceMaps
                                }
                            }
                        ]
                    })
                }
            ]
        },
        plugins: [
            new CleanWebpackPlugin([outputPath]),
            extractCssPlugin,
            new AutoDllPlugin({
                filename: '[name].js',
                entry: {
                    vendor: nodeLibs
                },
                plugins: minimizePlugins,
                inherit: function(mainConfig) {
                    const config = Object.assign({}, mainConfig);
                    delete config.entry;
                    delete config.output;
                    delete config.plugins;
                    return config;
                }
            })
        ].concat(minimizePlugins)
    }];
};
