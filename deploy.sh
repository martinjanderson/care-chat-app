#!/bin/bash
set -e

echo "Building web app with Flutter..."
flutter build web
echo "Flutter build completed."

echo "Deploying to Firebase..."
firebase deploy
echo "Firebase deploy completed."
