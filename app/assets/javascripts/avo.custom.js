import * as Stimulus from "https://unpkg.com/@hotwired/stimulus/dist/stimulus.umd.js";
import * as NestedForm from "https://unpkg.com/stimulus-rails-nested-form/dist/stimulus-rails-nested-form.umd.js";

const application = window.Stimulus.Application.start();
application.register("nested-form", window.StimulusRailsNestedForm);
