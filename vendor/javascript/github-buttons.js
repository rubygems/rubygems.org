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
 * Source: https://github.com/mdo/github-buttons/blob/7c1da76484288ce76fa061362fc1c1f0db1f6553/src/js.js
 * Modification: Changed params to read attributes from data attributes
 *               Execute only when .github-btn exists
 *               Remove title update (mdo/github-buttons@cbf5395b)
 *               Stripped to minimal needed code with no dependencies (show amount of stars)
 */

if (document.querySelectorAll('.github-btn').length) {
  (function() {
    'use strict';

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

    // Elements
    var button = document.querySelector('.gh-btn');
    var mainButton = document.querySelector('.github-btn');
    var text = document.querySelector('.gh-text');
    var counter = document.querySelector('.gh-count');

    // Parameters
    var user = mainButton.dataset.user;
    var repo = mainButton.dataset.repo;
    var type = mainButton.dataset.type;
    var count = mainButton.dataset.count;
    var size = mainButton.dataset.size;

    // Constants
    var LABEL_SUFFIX = ' on GitHub';
    var GITHUB_URL = 'https://github.com/';
    var API_URL = 'https://api.github.com/';
    var REPO_URL = GITHUB_URL + user + '/' + repo;
    var USER_REPO = user + '/' + repo;

    window.callback = function(obj) {
      if (obj.data.message === 'Not Found') {
        return;
      }

      counter.textContent = obj.data.stargazers_count && addCommas(obj.data.stargazers_count);
      counter.setAttribute('aria-label', counter.textContent + ' stargazers' + LABEL_SUFFIX);

      if (counter.textContent !== '') {
        counter.style.display = 'block';
        counter.removeAttribute('aria-hidden');
      }
    };

    // Set href to be URL for repo
    button.href = REPO_URL;

    var title;

    // Add the class, change the text label, set count link href
    mainButton.className += ' github-stargazers';
    text.textContent = 'Star';
    counter.href = REPO_URL + '/stargazers';
    title = text.textContent + ' ' + USER_REPO;

    button.setAttribute('aria-label', title + LABEL_SUFFIX);

    // Change the size if requested
    if (size === 'large') {
      mainButton.className += ' github-btn-large';
    }

    jsonp(API_URL + 'repos/' + user + '/' + repo);
  })();
}
