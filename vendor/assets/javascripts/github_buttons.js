/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this work except in compliance with the License.
 * You may obtain a copy of the License in the LICENSE file, or at:
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Soure repo: https://github.com/mdo/github-buttons
 * Modification: Changed params to read attributes from data-params
 *               Changed jsonp to invoke callback after GET url (JSON-P callback endpoint was used originally to avoid cross domain issues)
 *               Execute only when #github-btn exists
 */

// Read a page's GET URL variables and return them as an associative array.
// Source: http://jquery-howto.blogspot.com/2009/09/get-url-parameters-values-with-jquery.html
if ($("#github-btn").length) {
  var params = (function () {
    var vars = [],
        hash;
    var hashes = $('.github-btn').attr('data-params').split('&');
    for (var i = 0; i < hashes.length; i++) {
      hash = hashes[i].split('=');
      vars.push(hash[0]);
      vars[hash[0]] = hash[1];
    }
    return vars;
  }());

  var user = params.user,
      repo = params.repo,
      type = params.type,
      count = params.count,
      size = params.size,
      v = params.v,
      head = document.getElementsByTagName('head')[0],
      button = document.getElementById('gh-btn'),
      mainButton = document.getElementById('github-btn'),
      text = document.getElementById('gh-text'),
      counter = document.getElementById('gh-count'),
      labelSuffix = ' on GitHub';

  // Add commas to numbers
  function addCommas(n) {
    return String(n).replace(/(\d)(?=(\d{3})+$)/g, '$1,');
  }

  function jsonp(path) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', path, true);
    xhr.responseType = 'json';
    xhr.onload = function() {
      var status = xhr.status;
      if (status === 200) {
        var res = { data: { stargazers_count: xhr.response.stargazers_count } };
        callback(res);
      } else {
        console.log("Request to github failed with status:", status)
      }
    };
    xhr.send();
  }

  function callback(obj) {
    switch (type) {
      case 'watch':
        if (v === '2') {
          counter.innerHTML = addCommas(obj.data.subscribers_count);
          counter.setAttribute('aria-label', counter.innerHTML + ' watchers' + labelSuffix);
        } else {
          counter.innerHTML = addCommas(obj.data.stargazers_count);
          counter.setAttribute('aria-label', counter.innerHTML + ' stargazers' + labelSuffix);
        }
        break;
      case 'star':
        counter.innerHTML = addCommas(obj.data.stargazers_count);
        counter.setAttribute('aria-label', counter.innerHTML + ' stargazers' + labelSuffix);
        break;
      case 'fork':
        counter.innerHTML = addCommas(obj.data.network_count);
        counter.setAttribute('aria-label', counter.innerHTML + ' forks' + labelSuffix);
        break;
      case 'follow':
        counter.innerHTML = addCommas(obj.data.followers);
        counter.setAttribute('aria-label', counter.innerHTML + ' followers' + labelSuffix);
        break;
    }

    // Show the count if asked
    if (count === 'true' && counter.innerHTML !== 'undefined') {
      counter.style.display = 'block';
    }
  }

  // Set href to be URL for repo
  button.href = 'https://github.com/' + user + '/' + repo + '/';

  // Add the class, change the text label, set count link href
  switch (type) {
    case 'watch':
      if (v === '2') {
        mainButton.className += ' github-watchers';
        text.innerHTML = 'Watch';
        counter.href = 'https://github.com/' + user + '/' + repo + '/watchers';
      } else {
        mainButton.className += ' github-stargazers';
        text.innerHTML = 'Star';
        counter.href = 'https://github.com/' + user + '/' + repo + '/stargazers';
      }
      break;
    case 'star':
      mainButton.className += ' github-stargazers';
      text.innerHTML = 'Star';
      counter.href = 'https://github.com/' + user + '/' + repo + '/stargazers';
      break;
    case 'fork':
      mainButton.className += ' github-forks';
      text.innerHTML = 'Fork';
      button.href = 'https://github.com/' + user + '/' + repo + '/fork';
      counter.href = 'https://github.com/' + user + '/' + repo + '/network';
      break;
    case 'follow':
      mainButton.className += ' github-me';
      text.innerHTML = 'Follow @' + user;
      button.href = 'https://github.com/' + user;
      counter.href = 'https://github.com/' + user + '/followers';
      break;
  }
  button.setAttribute('aria-label', text.innerHTML + labelSuffix);

  // Change the size
  if (size === 'large') {
    mainButton.className += ' github-btn-large';
  }

  if (type === 'follow') {
    jsonp('https://api.github.com/users/' + user);
  } else {
    jsonp('https://api.github.com/repos/' + user + '/' + repo);
  }
}
