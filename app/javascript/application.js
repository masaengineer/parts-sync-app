// Entry point for the build script in your package.json
import { Turbo } from '@hotwired/turbo-rails';
Turbo.start();

import { Application } from '@hotwired/stimulus';
import { registerControllers } from './controllers';

// Import TourGuideJS styles
import "@sjmc11/tourguidejs/src/scss/tour.scss"

// Import and initialize iconify-icon
import 'iconify-icon';

const application = Application.start();
registerControllers(application);
