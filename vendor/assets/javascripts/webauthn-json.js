// Copyright (c) 2019 GitHub, Inc.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
var base64urlToBuffer = function (baseurl64String) {
  var padding = "==".slice(0, (4 - (baseurl64String.length % 4)) % 4)
  var base64String =
    baseurl64String.replace(/-/g, "+").replace(/_/g, "/") + padding
  var str = atob(base64String)
  var buffer = new ArrayBuffer(str.length)
  var byteView = new Uint8Array(buffer)
  for (var i = 0; i < str.length; i++) {
    byteView[i] = str.charCodeAt(i)
  }
  return buffer
}

var bufferToBase64url = function (buffer) {
  var byteView = new Uint8Array(buffer)
  var str = ""
  byteView.forEach(function(charCode) {
    str += String.fromCharCode(charCode)
  })
  var base64String = btoa(str)
  var base64urlString = base64String
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "")
  return base64urlString
}
