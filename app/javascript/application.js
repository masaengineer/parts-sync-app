// Entry point for the build script in your package.json
import { Turbo } from '@hotwired/turbo-rails';
Turbo.start();

import { Application } from '@hotwired/stimulus';
import ChartController from './controllers/chart_controller';

const application = Application.start();
application.register('chart', ChartController);

// DaisyUI theme controller
document.addEventListener('turbo:load', () => {
  const themeController = document.querySelector('.theme-controller');
  if (themeController) {
    themeController.addEventListener('change', (e) => {
      const html = document.querySelector('html');
      if (e.target.checked) {
        html.setAttribute('data-theme', 'dark');
      } else {
        html.setAttribute('data-theme', 'light');
      }
    });
  }
});
