// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import ChartController from "./chart_controller"
application.register("chart", ChartController)

import FlashController from "./flash_controller"
application.register("flash", FlashController)

import FormSubmitController from "./form_submit_controller"
application.register("form-submit", FormSubmitController)

import ModalController from "./modal_controller"
application.register("modal", ModalController)

import PasswordFieldController from "./password_field_controller"
application.register("password-field", PasswordFieldController)

import ThemeController from "./theme_controller"
application.register("theme", ThemeController)

import TourController from "./tour_controller"
application.register("tour", TourController)
