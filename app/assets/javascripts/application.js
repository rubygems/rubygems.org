// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery3
//= require jquery_ujs
//= require clipboard
//= require github_buttons
//= require webauthn-json
//= require_tree .

import $ from "jquery";
import jqueryUjsInit from "jquery-ujs";
jqueryUjsInit($);
import "@rails/ujs";
import "../../../vendor/assets/javascripts/github_buttons";

import "./api_key_form";
import "./autocomplete";
import "./clipboard_buttons";
import "./mobile-nav";
import "./multifactor_auths";
import "./pages";
import "./popup-nav";
import "./search";
import "./transitive_dependencies";
import "./webauthn";
