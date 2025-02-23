// Import and register all your controllers from the importmap under controllers/*

import FormSubmitController from './form_submit_controller';
import ChartController from './chart_controller';
import ThemeController from './theme_controller';
import FlashController from './flash_controller';
import PasswordFieldController from './password_field_controller';
import TourController from './tour_controller';

export function registerControllers(application) {
  application.register('form-submit', FormSubmitController);
  application.register('chart', ChartController);
  application.register('theme', ThemeController);
  application.register('flash', FlashController);
  application.register('password-field', PasswordFieldController);
  application.register('tour', TourController);
}
