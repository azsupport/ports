/*
 * src/setup_node_env/node_compat.js of azsupport/ports (textproc/kibana6): Kibana
 * 6.8 on the Node.js 24 of the ports, not on the Node.js 10.24.1 it was built for.
 * src/setup_node_env/index.js loads it first, in the place of
 * node_version_validator.js: bin/kibana, bin/kibana-plugin, bin/kibana-keystore and
 * the rc script all start there. It puts back what Node.js has taken away since 10
 * and Kibana still needs, as Node.js 10 had it, and nothing else:
 *
 * 1. util.isBoolean, isBuffer, isDate, isError, isFunction, isNull,
 *    isNullOrUndefined, isNumber, isObject, isPrimitive, isRegExp, isString,
 *    isSymbol, isUndefined and util.log: removed in Node.js 23 (DEP0045 to DEP0059);
 *    modules of node_modules still call them. util.isArray, deprecated, is still
 *    there: put back only if a later Node.js takes it away too.
 * 2. MD4: webpack 4 hashes with it (its module and chunk hashes, babel-loader names
 *    its cache files by it, terser-webpack-plugin its cache keys) whenever Kibana
 *    builds its bundles again (another set of plugins, a plugin installed), and
 *    the OpenSSL 3 of Node.js has MD4 only in its legacy provider:
 *    crypto.createHash('md4') throws ERR_OSSL_EVP_UNSUPPORTED. In its place MD5,
 *    of the same length, only while OpenSSL has no MD4: these hashes name files
 *    and cache entries, the bundles are the same. The workers of webpack
 *    (thread-loader) are node processes of their own: NODE_OPTIONS gets the
 *    --require of this file, which they inherit (Kibana passes NODE_OPTIONS on to
 *    them as their arguments too).
 * 3. A rejected promise that nothing handles: a warning, as in Node.js 10, not the
 *    end of the process (the default since Node.js 15). Kibana 6 adds its own
 *    handler only when pid.file is set.
 * 4. A name with IPv4 and IPv6 addresses: the IPv4 one first, as Node.js 10 took it
 *    (since Node.js 17 the order of the resolver, on FreeBSD ::1 for localhost):
 *    server.host is "localhost" by default, and Kibana would listen on [::1]:5601
 *    only, not on 127.0.0.1:5601 as before; elasticsearch.hosts has localhost too.
 *    As the Kibana of today starts its Node.js (--dns-result-order=ipv4first).
 * 5. No warnings of deprecated APIs (fs.R_OK, new Buffer(), url.parse() and more
 *    in the modules of 2019), as Node.js 10 had none: bin/kibana and the rc script
 *    run node with --no-warnings, bin/kibana-keystore and bin/kibana-plugin do not.
 */
'use strict';

var util = require('util');
var crypto = require('crypto');

// 1. util.is* and util.log of Node.js 10 (lib/util.js of v10.24.1)
function objectToString(o) {
  return Object.prototype.toString.call(o);
}
var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
function pad(n) {
  return n < 10 ? '0' + n : String(n);
}
function timestamp() {
  var d = new Date();
  var time = [pad(d.getHours()), pad(d.getMinutes()), pad(d.getSeconds())].join(':');
  return [d.getDate(), months[d.getMonth()], time].join(' ');
}
var legacyUtil = {
  isArray: Array.isArray,
  isBoolean: function isBoolean(arg) { return typeof arg === 'boolean'; },
  isBuffer: Buffer.isBuffer,
  isDate: util.types.isDate,
  isError: function isError(e) { return objectToString(e) === '[object Error]' || e instanceof Error; },
  isFunction: function isFunction(arg) { return typeof arg === 'function'; },
  isNull: function isNull(arg) { return arg === null; },
  isNullOrUndefined: function isNullOrUndefined(arg) { return arg === null || arg === undefined; },
  isNumber: function isNumber(arg) { return typeof arg === 'number'; },
  isObject: function isObject(arg) { return arg !== null && typeof arg === 'object'; },
  isPrimitive: function isPrimitive(arg) {
    return arg === null || (typeof arg !== 'object' && typeof arg !== 'function');
  },
  isRegExp: util.types.isRegExp,
  isString: function isString(arg) { return typeof arg === 'string'; },
  isSymbol: function isSymbol(arg) { return typeof arg === 'symbol'; },
  isUndefined: function isUndefined(arg) { return arg === undefined; },
  log: function log() { console.log('%s - %s', timestamp(), util.format.apply(util, arguments)); }
};
Object.keys(legacyUtil).forEach(function (name) {
  if (typeof util[name] !== 'function') {
    Object.defineProperty(util, name, {
      value: legacyUtil[name], writable: true, enumerable: true, configurable: true
    });
  }
});

// 2. MD4 of webpack 4: MD5 when OpenSSL has no MD4
var hasMd4 = true;
try {
  crypto.createHash('md4');
} catch (e) {
  hasMd4 = false;
}
if (!hasMd4) {
  var createHash = crypto.createHash;
  crypto.createHash = function (algorithm, options) {
    if (typeof algorithm === 'string' && algorithm.toLowerCase() === 'md4') {
      algorithm = 'md5';
    }
    return createHash.call(this, algorithm, options);
  };
}
// the node processes Kibana starts (the workers of webpack) load this file too
if (!/\s/.test(__filename) && (process.env.NODE_OPTIONS || '').indexOf(__filename) === -1) {
  process.env.NODE_OPTIONS = ((process.env.NODE_OPTIONS || '') + ' --require=' + __filename).trim();
}

// 3. an unhandled rejection: a warning, as in Node.js 10
if (process.listenerCount('unhandledRejection') === 0) {
  process.on('unhandledRejection', function (reason) {
    process.emitWarning('Unhandled promise rejection: ' + ((reason && reason.stack) || reason),
      'UnhandledPromiseRejectionWarning');
  });
}

// 4. the IPv4 address of a name first, as in Node.js 10
require('dns').setDefaultResultOrder('ipv4first');

// 5. deprecated APIs: no warnings
process.noDeprecation = true;
