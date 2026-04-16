resource "google_firebase_project" "cliniclarity_firebase" {
  provider = google-beta
  project  = "cliniclarity"
}

resource "google_firebase_web_app" "cliniclarity_web_app" {
  provider     = google-beta
  project      = "cliniclarity"
  display_name = "CliniClarity Web App"
  depends_on   = [google_firebase_project.cliniclarity_firebase]
}

data "google_firebase_web_app_config" "app_config" {
  provider   = google-beta
  project    = "cliniclarity"
  web_app_id = google_firebase_web_app.cliniclarity_web_app.app_id
}
