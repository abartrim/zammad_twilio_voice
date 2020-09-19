const fs = require('fs');
let version = '1.0.3';
let version_text = 'Bumping version to reload';
let template = {
  "name": "Twilio_Voice",
  "version": version,
  "vendor": "IT Shield LLC",
  "license": "MIT",
  "url": "https://www.myitshield.com",
  "buildhost": "gitlab.com",
  "builddate": new Date().toUTCString(),
  "change_log": [
    {
      "version": version,
      "date": new Date().toUTCString(),
      "log": version_text
    }
  ],
  "description": [
    {
      "language": "en",
      "text": "Simple Twilio Voice integration for Zammad"
    }
  ],
  "files": []
};

// Add files
let files = [
  "app/models/cti/driver/twilio.rb",
  "config/routes/integration_twilio.rb",
  "app/controllers/integration/twilio_controller.rb",
  "app/assets/javascripts/app/views/integration/twilio.jst.eco",
  "app/assets/javascripts/app/controllers/_integration/twilio.coffee",

  "db/addon/twilio_voice/20201007000001_twilio_voice.rb", // DB migratiom

  // These are for adding the controllor to the config, should investigate doing via startup code
  // "db/seeds/settings.rb",
  "app/controllers/cti_controller.rb",
  "app/assets/javascripts/app/controllers/cti.coffee"
];

const path = require('path');
const basedir = path.join(__dirname, 'twilio_voice');

// eslint-disable-next-line guard-for-in
for (let f in files) {
  // read file contents as base64
  // let file = path.join(basedir, files[f]);
  if (fs.existsSync(files[f])) {
    // let fileDirPath = path.join(basedir, path.dirname(files[f]));
    // fs.mkdirSync(fileDirPath, { recursive: true });
    // fs.copyFileSync(path.join(__dirname, files[f]), path.join(basedir, files[f]));
    template.files.push({
      "location": files[f],
      "permission": 664,
      "encode": "base64",
      "content": fs.readFileSync(files[f]).toString('base64')
    }
    );
  }
}

console.log(JSON.stringify(template, null, 2));