// Entry point for the build script in your package.json

import { Turbo } from '@hotwired/turbo-rails';
Turbo.start();

import { Application } from '@hotwired/stimulus';
import { registerControllers } from './controllers';

const application = Application.start();
registerControllers(application);
