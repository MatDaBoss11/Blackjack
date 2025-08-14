# Blackjack Trainer

A Flutter web application for learning optimal blackjack strategy with AI-powered feedback.

## Features

- Interactive blackjack gameplay with optimal strategy recommendations
- AI-powered feedback for incorrect moves using Google's Gemini API
- Support for splitting pairs and doubling down
- Real-time statistics tracking
- Responsive web design

## Live Demo

After deployment, your app will be available at: `https://yourusername.github.io/blackjack/`

## Local Development

### Prerequisites

- Flutter 3.32.8 or later
- Dart 3.8.1 or later

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/blackjack.git
cd blackjack
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app locally:
```bash
flutter run -d chrome
```

### Building for Web

```bash
flutter build web --release
```

## Deployment to GitHub Pages

This project is configured for automatic deployment to GitHub Pages using GitHub Actions.

### Setup Instructions

1. Push your code to GitHub
2. Go to your repository settings
3. Navigate to Pages → Source → GitHub Actions
4. The workflow will automatically build and deploy your app when you push to the main/master branch

### Manual Deployment

If you prefer manual deployment:

1. Build the web version:
```bash
flutter build web --release --base-href="/blackjack/"
```

2. Deploy the `build/web` folder to your web hosting service

## Project Structure

- `lib/main.dart` - Main application code with blackjack game logic
- `lib/gemini_service.dart` - AI feedback service integration
- `web/` - Web-specific configuration files
- `.github/workflows/deploy.yml` - GitHub Actions workflow for deployment

## Technologies Used

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Google Gemini AI** - AI-powered feedback system
- **GitHub Actions** - CI/CD for deployment
- **GitHub Pages** - Web hosting
